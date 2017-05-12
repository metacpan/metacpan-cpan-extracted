use strict;

package Tamino::Tran;
use base qw/Class::Accessor Class::Data::Inheritable/;

use XML::Bare 0.271;

use Tamino::Tran::Prepared;
use Tamino::Tran::Cursor;

# require MIME::Base64 follows
# require XML::Twig follows

=head1 NAME

Tamino::Tran - The L<Tamino> driver's main class wrapping Tamino API.

=head1 SYNOPSIS

    use Tamino;
    
    my $tamino_client = Tamino->new(
        server      => '127.0.0.1/tamino'
        db          => 'mydb'
    );
    
    # $t will be a Tamino::Tran object                                 
    my $t = $tamino_client->begin_tran
        or die $tamino_client->error;
        
    $c = $t->xquery(q{for $x in input()/ return $x}) or die $t->error;
    
    $c = $t->xquery_cursor(q{
        for $x in collection('mycollection')/doctype/xxx[@yyy=%s][zzz='%s']
        return $x
    }, "('y1','y2')", "z1") or die $t->error;

    while($xml_bare_simple_tree = $c->fetch) {
        print XML::Simple::XMLout($xml_bare_simple_tree, KeyAttr => []);
    }

    $t->delete(q{for $x in input()/doc[@bad='yes'] return $x}) or die $t->error;

=head1 DESCRIPTION

This is just an API wrapper.
This driver is based on L<LWP::UserAgent>, L<XML::Bare>, and inherits from L<Class::Accessor> and L<Class::Data::Inheritable>.

=cut


__PACKAGE__->mk_ro_accessors(qw/url ua tamino _isolation_level _lock_mode _lock_wait _encoding messages/);
__PACKAGE__->mk_accessors(qw/_sid _sk isolation_level lock_mode lock_wait _accept_session encoding queries queries_time/);

__PACKAGE__->mk_classdata($_) for qw/prepared_class cursor_class xml_twig_class xml_twig_elt_class _debug pretty_print /;
__PACKAGE__->mk_accessors(qw/error   prepared_class cursor_class xml_twig_class xml_twig_elt_class _debug pretty_print /);

__PACKAGE__->prepared_class('Tamino::Tran::Prepared');
__PACKAGE__->cursor_class('Tamino::Tran::Cursor');
__PACKAGE__->xml_twig_class('XML::Twig');
__PACKAGE__->xml_twig_elt_class('XML::Twig::Elt');

__PACKAGE__->pretty_print('indented');

my $isolation_levels = {
    map {$_=>$_} qw /uncommittedDocument committedCommand stableCursor stableDocument stableDocument/
};

my $lock_modes = {
    map {$_=>$_} qw/unprotected shared protected/
};

my $yesno = {
    map {$_=>$_} qw/yes no/
};

sub parse_xml {
    my $self = shift;
    my $xml = XML::Bare->new(text => ${$_[0]}, forcearray => {
        map {$_ => 1} (@{$self->{_forcearray}}, @_, qw/ino:message ino:messagetext ino:messageline/)
    });
    return unless ($xml->simple()->{'ino:response'});
    return $xml->{xml}->{'ino:response'};
}

=head1 CONSTRUCTOR

Constructor is called internally by L<Tamino> class object.

=cut 

sub new ($) {
    my $class = shift;
    my %args = @_;
    $class = ref $class || $class;
    my $self = $class->SUPER::new({
        _isolation_level => $isolation_levels->{$args{isolation_level}} || 'committedCommand',
        _lock_mode       => $lock_modes->{$args{lock_mode}},
        _lock_wait       => $yesno->{$args{lock_wait}} || 'yes',
        encoding         => $args{encoding} || 'UTF-8',
        
        pretty_print     => $class->pretty_print,
        xml_twig_class   => $class->xml_twig_class,
        xml_twig_elt_class=>$class->xml_twig_elt_class,
        
        cursor_class     => $class->cursor_class,
        prepared_class   => $class->prepared_class,

        queries          => 0,
        queries_time     => 0,
        
        (map { $_ => $args{$_} } grep {exists $args{$_}} qw/url ua tamino _debug/),
    });
    $self->_accept_session(0);
    
    unless($args{_no_connect}) {
        unless($self->connect) {
            $class->error($self->error);
            return;
        }
    }
    
    return $self;
}

sub dbg {
    my $obj=shift;
    my $w = (ref$obj||$obj)."::".sprintf(shift, @_)."::\n";
    warn $w;
}

my $__t;
sub _cmd ($$;@) {
    my ($self, $data, %opts) = @_;
    my @h;
    
    $self->{queries}++;
    $self->{tamino}->{queries}++;

    $self->error('');
    $self->{messages} = '';
    if($self->_sid && $self->_sk) {    
        push @h, "X-INO-Sessionid"  => $self->_sid,
                 "X-INO-Sessionkey" => $self->_sk;
    }
    
    $data->{_isolationLevel} = $isolation_levels->{$self->{isolation_level}} if($self->{isolation_level});
    $data->{_lockMode} = $lock_modes->{$self->{lock_mode}} if($self->{lock_mode});
    $data->{_lockWait} = $yesno->{$self->{lock_wait}} if($self->{lock_wait});
    $data->{_encoding} = $self->{encoding} if($self->{encoding});
    
    if($opts{send_session}) {
        $data->{_sessionid} = $self->{_sid};
        $data->{_sessionkey} = $self->{_sk};
    }
    
    $self->dbg("send==".join("&", map { "$_=$data->{$_}" } keys %$data )) if($self->{_debug});
      
    $__t = timer->new( \($self->{queries_time}, $self->{tamino}->{queries_time}) );
    my $r = $self->ua->post($self->{url}, @h, Content => [%$data]);
    $self->dbg("TIME=%.6f",$__t->close) if($self->{_debug});
    undef $__t;

    if($r->is_success) {
        $self->dbg("OK...") if($self->{_debug});
        if($self->{_accept_session}) {
            unless($r->header('X-INO-Sessionid') && $r->header('X-INO-Sessionkey')) {
                $self->error('Session was not established');
                return;
            }
            $self->{_sid} = $r->header('X-INO-Sessionid');
            $self->{_sk} = $r->header('X-INO-Sessionkey');
            $self->dbg("Session established: %s %s", $self->{_sid}, $self->{_sk}) if($self->{_debug});
        } elsif($self->{_sid}) {
            if($self->{_sid} != $r->header('X-INO-Sessionid')) { 
                $self->error('Session broken');
                return;
            }
            $self->{_sk} = $r->header('X-INO-Sessionkey');
            $self->dbg('Session continued: %s %s', $self->{_sid}, $self->{_sk}) if($self->{_debug});
        }
        return $self->_parse_response($r, %opts);
    } else {
        $self->error("HTTP Error %d: %s", $r->code, $r->message);
        return;
    }
}


sub _parse_response ($$@) {
    my ($self, $r, %opts) = @_;
    
    my $d = $r->content;
    $self->dbg("RESULT: ===============\n%s\n===============",$d) if($self->{_debug});
    
    my $x = $self->parse_xml(\$d,
            (wantarray ? ( $opts{result} ) : ()),
            ($opts{_twig_handlers} ? (map { m{\w+$} && $& } keys %{$opts{_twig_handlers}}) : ())
    ) or $self->error("Bad XML received!") and return;
        
    my $ret = 0;
    for my $m (@{$x->{'ino:message'}}) {
        my $retval = $m->{'ino:returnvalue'};
        if($retval && !$ret) {
            $ret = $retval;
            $self->error($ret.": ".join('\n', map { $_->{'ino:code'}.": ".$_->{value} } @{$m->{'ino:messagetext'}}) );
        }
        $self->{messages} .= $ret.": ".join('\n', @{$m->{'ino:messageline'}})."\n";
    }
    return if ($ret);

    if ( $opts{_twig_handlers} ) {
        for my $h (keys %{$opts{_twig_handlers}}) {
            my $n = $x;
            $n = $n->{$_} or last for split'/',$h;
            last unless $n;
            $opts{_twig_handlers}->{$h}->(undef, $n);
        }
    }
    
    if($self->{_plaintext}) {
        return \$d;
    }
        
    return $opts{result} ? ( 
            wantarray ? @{$x->{$opts{result}}} : (
                defined wantarray ? $x->{$opts{result}} : undef
        )) : 1;
}

sub _open_cursor ($$;$@) {
    my ($self, $data, %opts) = @_;
    return $self->cursor_class->new(tran => $self, data => $data, %opts);
}


=head1 METHODS

=head2 connect

=over 4

    $t->connect or die $t->error;

Starts new transaction session. Transaction is started implicitly by the first DB update action.
After this call, all operations are made in transaction context.

=back

=cut 

sub connect ($) {
    my ($self) = @_;
    $self->{_accept_session} = 1;
    my $ret = $self->_cmd({
        _connect => '*',
        $self->{_isolation_level} ? ( _isolationLevel => $self->{_isolation_level} ) : (),
        $self->{_lock_mode} ? ( _lockMode => $self->{_lock_mode} ) : (),
        $self->{_lock_wait} ? ( _lockWait => $self->{_lock_wait} ) : (),
    });
    $self->{_accept_session} = 0;
    return defined $ret;
}


=head2 disconnect

=over 4

    $t->disconnect or die $t->error;

Ends transaction session. All uncommitted data is rolled back.
After this call, all operations are made in non-transactional context.

=back

=cut 

sub disconnect ($) {
    my ($self) = @_;
    if(defined $self->_cmd({ _disconnect => '*' }) ) {
        $self->{_sid} = undef;
        $self->{_sk}  = undef;
        return 1;
    }
    return 0;
}

sub DESTROY {
    my ($self) = @_;
    $self->rollback;
    $self->disconnect;
}


=head2 commit

=over 4

    $t->commit or die $t->error;

Commit changes. If you want such thing as autocommit - just don't start transaction session (C<< $t = $tamino_client->begin(); >>)

=back

=cut 

sub commit ($) {
    my ($self) = @_;
    return defined $self->_cmd({ _commit => '*' }) if($self->{_sk});
    return 1;
}


=head2 rollback

=over 4

    $t->rollback or die $t->error;

Rollback changes.

=back

=cut 

sub rollback ($) {
    my ($self) = @_;
    return defined $self->_cmd({ _rollback => '*' }) if($self->{_sk});
    return 1;
}


=head2 prepare

=over 4

    my $stmt = $t->prepare($query, \%vars) or die $t->error;
    my $stmt = $t->prepare(q{for $x in input()/xxx[@yyy=$y][zzz=$z]}, {
        y => 'string',
        z => 'xs:integer'
    }) or die $t->error;

Initializes a prepared statement. The C<$query> is compiled by server, and
can be executed later with parameters. Available only with Tamino v4.4+

The C<\%vars> paramter specifies parameter types. Paramter names specified without B<$> sign.

Returns L<Tamino::Tran::Prepared> object. 

=back

=cut 

sub prepare ($$$) {
    my ($self, $query, $vars) = @_;
    return $self->prepared_class->new(tran => $self, query => $query, vars => $vars);
}


=head2 xquery

=over 4

    my $xml = $t->xquery($query_fmt, @args) or die $t->error;
    my $xml = $t->xquery(q{
        for $x in collection('mycollection')/doctype/xxx[@yyy=%s][zzz='%s']
        return $x
    }, "('y1','y2')", "z1") or die $t->error;
    print XML::Simple::XMLout($xml);

Returns L<XML::Simple>-like tree object representing the result of C<< sprintf($query_fmt, @args) >>-X-Query
This L<sprintf|perlfunc/sprintf> trick is used to avoid interpolation crap,
because X-Query uses the same C<$var>-form variables, just like we do.
Look at L<plaintext|/plaintext> method if you want to get plain-text XMLs.

=back

=cut 

sub xquery ($$;@) {
    my ($self, $query) = (shift, shift);
    return $self->_cmd({ _xquery => sprintf($query,@_) }, result => 'xq:result');
} 


=head2 xquery_cursor

=over 4

    my $cursor = $t->xquery_cursor($query_fmt, [\%cursor_opts,] @args) or die $t->error;

The same as L</xquery>, except that it opens cursor for the X-Query and
returns L<Tamino::Tran::Cursor> object.

Pass a HASHREF as 2-nd parameter to specify cursor options, otherwise it will be treated as the first of B<args>
I<cursor_options> can be:

C<< scrollable => 1 >>

C<< vague => 1 >>

C<< fetch_size => 1 >>

C<< no_fetch => 1 >> this tells Tamino server not to fetch-on-open.

For What-This-All-Means read Tamino Documentation.

=back

=cut 

sub xquery_cursor ($$;@) {
    my ($self, $query, $cursor_opts) = (shift, shift, shift);
    if(ref $cursor_opts eq 'HASH') {
        $cursor_opts = { map { $_ => $cursor_opts->{$_} } qw/scrollable vague fetch_size no_fetch/ };
    } else {
        unshift @_, $cursor_opts;
    }
    return $self->_open_cursor({ _xquery => sprintf($query,@_) },
        result => 'xq:result',
        %$cursor_opts
    );
} 


=head2 xql

=over 4

    my $xml = $t->xql($query_fmt, @args) or die $t->error;
    print XML::Simple::XMLout($xml);

The same as L</xquery>, except that it uses B<XQuery>, not B<X-Query>.
What is the difference? I don't know. Read the documentation for Tamino.

=back

=cut 

sub xql ($$;@) {
    my ($self, $query) = (shift, shift);
    return $self->_cmd({ _xql => sprintf($query,@_) }, result => 'xql:result');
}


=head2 xql_cursor

=over 4

    my $cursor = $t->xql_cursor($query_fmt, \%cursor_opts, @args) or die $t->error;

The same as L</xquery_cursor>, except that it uses B<XQuery>, not B<X-Query>.
What is the difference? I don't know. Read the documentation for Tamino.

=back

=cut 

sub xql_cursor ($$;@) {
    my ($self, $query, $cursor_opts) = (shift, shift, shift);
    if(ref $cursor_opts eq 'HASH') {
        $cursor_opts = { map { $_ => $cursor_opts->{$_} } qw/scrollable vague fetch_size no_fetch/ };
    } else {
        unshift @_, $cursor_opts;
    }
    return $self->_open_cursor({ _xql => sprintf($query,@_) },
        result => 'xql:result',
        %$cursor_opts
    );
}


=head2 delete

=over 4

    $t->delete($xquery_fmt, @args) or die $t->error;

Delete documents matching the X-Query.
Parameters are the same as for L</xquery>.

=back

=cut 

sub delete ($$;@) {
    my ($self, $query) = (shift, shift);
    return defined $self->_cmd({ _delete => sprintf($query,@_) });
}

=head2 process

=over 4

    $t->process( [ { name => $name, id => $id, data => \$xml, %options } , ... ], %OPTIONS );

Takes ARRAYREF of documents and
submit a PROCESS command, which does the following for each document:

Replaces document if B<name> and/or B<id> specified (the document MUST exists, and B<name> MUST match B<id>).
Returns I<TRUE> on success.

Stores new document if neither B<name> nor B<id> was specified.
Returns ARRAYREF of HASHREFs of I<id>, I<name> and I<collection>.

B<data> parameter is a scalarref poiting to the [XML] document or an L<XML::Twig::Elt> object.

B<%options> may include:

C<< escape => 1 >> to specify that B<data> is an not XML string, so it will be escaped.

C<< base64 => 1 >> to Base64-encode B<data> string.

C<< collection => $my_collection_name >> to specify where to store documents.
You MUST provide this attribute if you haven't pass it into L<Tamino> constructor,
otherwise the default "ino:etc" collection will be used.

B<%OPTIONS> may include:

C<< encoding => $enc >> to specify encoding of DOCUMENTS being processed.

=back

=cut 

sub process ($$;@) {
    my ($self, $docs, %opts) = @_;
    my $x = $self->xml_twig_class;
    $x =~ s!::!/!gs;
    require $x.".pm";
    my $xml = $self->xml_twig_class->new;
    $xml->parse(sprintf(
        q{<?xml version="1.0" encoding="%s"?>
          <ino:request xmlns:ino="http://namespaces.softwareag.com/tamino/response2" />},
    $opts{encoding} || $self->encoding || $self->_encoding));
    
#   <ino:object ino:docname="name" ino:id="id" >
#        data
#   </ino:object>

    my $i = 0;
    my $inserting = 0;
    my $root = $xml->root;
    for my $d (@$docs) {
        my $e = $self->xml_twig_elt_class->new('ino:object');
        $e->set_att('ino:id'         => $d->{id})         if defined $d->{id};
        $e->set_att('ino:docname'    => $d->{name})       if defined $d->{name};
        $e->set_att('ino:collection' => $d->{collection}) if defined $d->{collection};
        $e->paste(last_child => $root);
        $inserting += int(!defined $d->{id} && !defined $d->{name});
        if(eval{!!$d->{data}->isa($self->xml_twig_class)}){
            $d->{data} = $d->{data}->root;
        }
        if(eval{!!$d->{data}->isa($self->xml_twig_elt_class)}) {
            $d->{data}->copy->paste(last_child => $e);
        } else {
            if($d->{base64}) {
                require MIME::Base64;
                $e->set_text(MIME::Base64::encode(${$d->{data}}));
            } elsif($d->{escape}) {
                $e->set_text(${$d->{data}});
            } else {
                my $xml = $self->xml_twig_class->new;
                $xml->safe_parse(${$d->{data}});
                if($@) {
                    $self->error("Doc#%d: error in XML: %s", $i, $@) and return;
                }
                $xml->root->move(last_child => $e);
            }
        }
    } continue {
        $i++;
    }
    
    return defined $self->_cmd({ _process => $xml->sprint }) unless $inserting;

    my @objs = $self->_cmd({ _process => $xml->sprint }, result => 'ino:object');
    return [ map +{
        id          => $_->{'ino:id'},
        name        => $_->{'ino:docname'},
        collection  => $_->{'ino:collection'},
    }, @objs ];
}

sub define {
    my ($self, $doc) = @_;
    return defined $self->_cmd({ _define => $doc });
}

sub define_collection ($$;$) {
    my ($self, $name, $opt) = @_;
    $opt ||= 'required';
    my $xml = qq{
        <tsd:collection name="$name"
             xmlns:tsd="http://namespaces.softwareag.com/tamino/TaminoSchemaDefinition">
            <tsd:schema use="$opt"/>
        </tsd:collection>    
    };
    return defined $self->_cmd({ _define => $xml });
}

sub undefine {
    my ($self, $doc) = @_;
    return defined $self->_cmd({ _undefine => $doc });
}

=head1 MISC METHODS

=over 4

=item error

=item messages

    print $t->messages; # any messages from server.
    warn $t->error;

=back

=cut 

sub error ($;@) {
    my $self = shift;
    if(@_) {
        $self->{error} = sprintf(shift, @_);
        $self->dbg("ERROR: %s",$self->{error}) if($self->{_debug});
        return 1;
    } else {
        return $self->{error};
    }
}

sub simplify ($$) {
    my ($self, $arg) = @_;
    $self->{_simplify} = $arg;
    return unless $arg;
    my %a = @$arg;
    $self->{_forcearray} = $a{forcearray};
}

=pod

=over 4

=item forcearray

    $t->forcearray(qw/tag1 tag2/);
    $t->forcearray([qw/tag1 tag2/]);

Force these tags to be represented as an array, even if there is only one.

=back

=cut 

sub forcearray ($;@) {
    my $self = shift;
    $self->{_forcearray} = ref $_[0] ? $_[0] : [@_];
}

=pod

=over 4

=item plaintext

    $t->plaintext($boolean);

If true, all requests that return an XML tree will return a SCALARREF to plain XML data

=back

=cut 

sub plaintext ($;$) {
    my $self = shift;
    $self->{_plaintext} = $_[0];
}

=pod

=over 4

=item encoding

    $t->encoding('other_encoding'); # change encoding

=back

=head2 TRANSACTION CONTROL METHODS

    $t->isolation_level($level);    
    $t->lock_mode($mode);    
    $t->lock_wait($wait);    

Set new transaction options.
The same as L<Tamino/begin_tran> options.

=head1 SUBCLASSING

You can subclass I<Tamino::Tran>.
You can tell I<Tamino::Tran> to use subclassed
L<XML::Twig>,
L<XML::Twig::Elt>,
L<Tamino::Tran::Prepared>,
L<Tamino::Tran::Cursor>
by saying:

    $obj->xml_twig_class("My::XML::Twig");
    $obj->xml_twig_elt_class("My::XML::Twig::Elt");
    
    $obj->prepared_class("My::Tamino::Tran::Prepared");
    $obj->cursor_class("My::Tamino::Tran::Cursor");

where $obj can be an object, so changes are made to that object,
or 'Tamino::Tran' - class name, so changes are made class-wide, excepting existing objects.

=cut

package timer;
use Time::HiRes qw/gettimeofday/;

sub new {
    my $class = shift;
    return bless [ sprintf("%d.%06d", gettimeofday), @_  ], $class;
}

sub close {
    my $self = shift;
    my $t = sprintf("%d.%06d", gettimeofday) - shift @$self;
    $$_ += $t for @$self;
    @$self = ();
    return $t;
}

sub DESTROY {
    my $self = shift;
    return unless(@$self);
    my $t = sprintf("%d.%06d", gettimeofday) - shift @$self;
    $$_ += $t for @$self;
}

1;

