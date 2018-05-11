package PPI::Transform::Doxygen;

=pod

=head1 NAME

PPI::Transform::Doxygen - PPI::Transform class for generating Doxygen input

=head1 SYNOPSIS

  use PPI;
  use PPI::Transform::Doxygen;

  my $transform = PPI::Transform::Doxygen->new();

  # appends Doxygen Docs after __END__ (default when no output is given)
  $transform->file('Module.pm');

  # prints Doxygen docs for use as a doxygen filter
  $transform->file('Module.pm' => \*STDOUT);

=head1 DESCRIPTION

This module is normally used by the script L<ppi_transform_doxygen> that is
part of this distribution and acts as a doxygen input filter (look for
B<INPUT_FILTER> in the Doxygen docs).

There is already L<Doxygen::Filter::Perl> doing roughly the same task, but it
uses special doxygen comments.

The goal of PPI::Transform::Doxygen is to use only POD documentation with a
minimal amount of special syntax, while still producing decent results with
doxygen.

As doxygen is not able to parse perl directly, the input filter will
convert the source so that it will look like C++.

=head1 CONVENTIONS

The only thing really needed, is documenting your methods and functions with
a POD tag B<=head2> that contains a function string with parentheses ( it has
to match the regular expression /[\w:]+\(.*\)/) like so:

  =head2 do_things()

  This function does things

  =cut

  sub do_things {
      print "Hi!\n";
  }

or so:

  =head2 class_method $obj THINGY::new(%args)

  Creates a new THINGY object

  =cut

  sub new {
      my($class, %args) = @_;
      return bless(\%args, $class);
  }


All other POD documentation (including other =head2 tags) is added as HTML
(provided by Pod::POM::View::HTML) into the Doxygen section named
B<Detailed Description>. IMHO it looks better when this is at the top of the
doxygen docs. Look under L</DETAILS ON TOP> on how to do that.

=head1 FUNCTION HEADERS

The complete syntax of a =head2 function description is:

C<< =head2 [<category>] [<return_value>] <name>(<parameters>) >>

=over

=item category (optional)

The category defines the type of the function definition. The values
C<function> and C<class_method> result in the function being tagged
as B<static> for Doxygen. Other values will be ignored, which will result
interpreting the function as method.

=item return_value (optional)

Since Doxygen expects C++ input, a return value is mandatory and will
default to B<void>. A given string will be passed to Doxygen as is, so be
careful with non word characters.

=item name

The function name with optional package name e.g. C<My::Module::test>. The
module will try to map the function name to the current package when none is
given. If your code is correctly parsable with PPI, then this should work.

If the corresponding subroutine is not found it will be tagged as B<virtual>
to Doxygen. This is useful for dynamically generated functions (e.g via
AUTOLOAD). Yes this has nothing to do with the C++ virtual keyword, but so
what? If you want to have the virtual subroutine mapped to the correct
namespace you will have to add it to the subs name
(e.g. C< MyClass::mysub() >)

Subroutine names with leading underscore will be tagged as B<private>
for Doxygen.

If there is no package declaration, the subroutine is created in the main
namespace, named C<< <script_or_module_name>_main >>.

=item parameters

The subroutine's comma separated parameter list. References are given in
dereference syntax so C<%$varname> specifies a hash reference. This will
be given as C<type name> to Doxygen e.g. C<subname(hash_ref varname)>.

=back

=head1 SIGNATURES

If you are using subroutine signatures, they will be parsed for information
and you can put the pod after the sub declaration like so:

    sub my_sig_sub ($self, $first = 'default', $second=[], %args) {
    =for method $self

    Sub documentation.

    =cut

        print join(' ', $first, @$second), "\n";
        return $self;
    }

In that case there is no redundant information you'll have to synchronize on
each change.
In that case the first parameter behind the B<=for> has to be C<method>,
C<function> or C<class_method>. The second parameter specifies the return
value.
A conflicting B<=head2> declaration for the same subroutine will take
precedence.

=head1 DETAILS ON TOP

For having the non subroutine POD documentation at the top of the Doxygen
page do the following:

=over

=item 1.

Create a doxygen layout XML file with C<doxygen -l>

=item 2.

Edit the XML file. Move C<< <detaileddescription title=""/> >> up to the
line directly behind C<< <briefdescription visible="yes"/> >>

=item 3.

Specify the file under C<LAYOUT_FILE> in your Doxyfile.

=back

=head1 METHODS

=cut

use strict;
use warnings;

use parent 'PPI::Transform';

use 5.010001;
use PPI;
use File::Basename qw(fileparse);
use Pod::POM;
use Pod::POM::View::Text;
use PPI::Transform::Doxygen::POD;
use Params::Util qw{_INSTANCE};

our $VERSION = '0.3';

my %vtype = qw(% hash @ array $ scalar & func * glob);

my %defaults = (
    rx_version  => qr/our\s*\$VERSION\s*=\s*["']([\d\.]+)/,
    rx_revision => qr/\$(?:Id|Rev|Revision|LastChangedRevision)\:\s*(\d+)\s*\$/,
    rx_parent   => qr/use\s+(?:base|parent|Mojo::Base)\s+["']?([\w:]+)["']?/,
);

#=================================================

=head2 $obj new(%args)

B<Constructor>

There are 3 optional arguments for extracting a version number, a revision
number and the parent class. Their values have to consist of a regex with one
capture group. The key C<<overwrite>> defines the behaviour when there is no
output device on calling C<<file()>>. Default behaviour is to append the
doxygen docs after an __END__ Token. Setting overwrite to a true value will
overwrite the input file.

The defaults are:

    rx_version  => qr/our\s*\$VERSION\s*=\s*["']([\d\.]+)/,
    rx_revision => qr/\$(?:Id|Rev|Revision|LastChangedRevision)\:\s*(\d+)\s*\$/,
    rx_parent   => qr/use\s+(?:base|parent|Mojo::Base)\s+["']?([\w:]+)["']?/,
    overwrite   => 0,

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = shift->SUPER::new(%defaults);

    @$self{ keys %args } = values %args;

    return $self;
}

#=================================================

=head2 file($in, $out)

Start the transformation reading from C<$in> and saving to C<$out>. C<$in>
has to be a filename and C<$out> can be a filename or a filehandle.
If C<$out> is not given, behaviour is defined by the parameter overwrite
(see C<new()>).

=cut

sub file {
    my ($self, $in, $out) = @_;

    return unless $in;

    my $preserve = !$out && !$self->{overwrite};

    my $Document = PPI::Document->new($in) or return undef;
    $Document->{_in_fn} = $in;
    $self->document($Document, $preserve) or return undef;

    $out //= $in;

    if ( ref($out) eq 'GLOB' ) {
        print $out $Document->serialize();
    } else {
        $Document->save($out);
    }
}

#=================================================

=head2 document($ppi_doc, $preserve)

This is normally called by C<file()> (see the docs for
L<PPI::Transform>). It will convert a PPI::Document object
in place.

=cut

sub document {
    my ( $self, $doc, $preserve ) = @_;

    _INSTANCE( $doc, 'PPI::Document' ) or return undef;

    my $pkg_subs = $self->_parse_packages_subs($doc);

    my($fname, $fdir, $fext) = fileparse( $doc->{_in_fn}, qr/\..*/ );

    my($pod_txt, $sub_info) = $self->_parse_pod($doc, $fname);

    _integrate_sub_info($pkg_subs, $sub_info);

    my @packages = sort keys %$pkg_subs;
    my $file_pod = $pod_txt if @packages == 1 and $packages[0] eq '!main';

    my $dxout = _out_head($fname . $fext, $file_pod);

    for my $pname ( @packages ) {

        my @parts     = split( /::/, $pname );
        my $short     = pop @parts;
        my $namespace = join( '::', @parts ) || '';

        $dxout .= _out_class_begin(
            $pname, $short, $namespace, $fname,
            $pkg_subs->{$pname}{inherit},
            $pkg_subs->{$pname}{used},
            $pkg_subs->{$pname}{version},
            $pkg_subs->{$pname}{revision},
            $pname eq $fname ? $pod_txt : '',
        );

        $dxout .= _out_process_subs( $pname, $pkg_subs, $sub_info );

        $dxout .= _out_class_end($namespace);
    }

    unless ($preserve) {
        $_->delete for $doc->children();
    }

    my $end_tok = $doc->find_first('PPI::Token::End') || PPI::Token::End->new();
    $end_tok->add_content($dxout);
    $doc->add_element($end_tok);
}


sub _strip { my $str = shift; $str =~ s/^ +//mg; $str }


sub _out_head {
    my($fn, $txt) = @_;

    $txt //= '';
    my $out = _strip(qq(
        /** \@file $fn
        $txt
        */
    ));

    return $out;
}


sub _get_used_modules {
    my($root) = @_;

    my %used;
    for my $chld ( $root->schildren() ) {
        next unless $chld->isa('PPI::Statement::Include');
        next if $chld->pragma();
        $used{$chld->module()} = 1
    }
    return \%used;
}


sub _parse_packages_subs {
    my($self, $doc) = @_;

    my %pkg_subs;

    my @main_pkgs = grep {
        $_->isa('PPI::Statement::Package')
    } $doc->children();

    unless (@main_pkgs) {
        $pkg_subs{'!main'}{used} = _get_used_modules($doc);
        my($v, $r) = $self->_get_pkg_version($doc);
        $pkg_subs{'!main'}{version}  = $v;
        $pkg_subs{'!main'}{revision} = $r;
    }

    my $stmt_nodes = $doc->find('PPI::Statement') || [];
    for my $stmt_node ( @$stmt_nodes ) {

        my $pkg  = '!main';
        next unless $stmt_node->class() eq 'PPI::Statement::Sub'
            or $stmt_node->child(0) eq 'has';

        my $node = $stmt_node;
        while ($node) {
            if ( $node->class() eq 'PPI::Statement::Package' ) {
                $pkg = $node->namespace();
                unless ( $pkg_subs{$pkg}{version} ) {
                    my($v, $r) = $self->_get_pkg_version($node->parent());
                    $pkg_subs{$pkg}{version}  = $v;
                    $pkg_subs{$pkg}{revision} = $r;
                }
                unless ( defined $pkg_subs{$pkg}{inherit} ) {
                    my ($inherit) = _find_first_regex(
                        $node->parent(),
                        'PPI::Statement::Include',
                        $self->{rx_parent},
                    );
                    $pkg_subs{$pkg}{inherit} = $inherit;
                }
                unless ( defined $pkg_subs{$pkg}{used} ) {
                    my $parent = $node->parent();
                    $pkg_subs{$pkg}{used} = _get_used_modules($parent)
                      if $parent;
                }
            }
            $node = $node->previous_sibling() || $node->parent();
        }

        my $sub_name = $stmt_node->class() eq 'PPI::Statement::Sub'
                     ? $stmt_node->name
                     : $stmt_node->child(2)->content;

        for my $sn ( grep { /\w/ && $_ ne 'qw' } split(/\W+/, $sub_name) ) {
            $pkg_subs{$pkg}{subs}{ $sn } = $stmt_node;
        }
    }

    return \%pkg_subs;
}


sub _out_process_subs {
    my($class, $pkg_subs, $sub_info) = @_;

    my $sub_nodes = $pkg_subs->{$class}{subs};

    my $out = '';

    my %types;
    for my $sname ( sort keys %$sub_nodes ) {
        my $si = $sub_info->{$sname} || {
            type    => $sname =~ /^_/ ? 'private' : 'public',
            rv      => 'void',
            params  => [],
            name    => $sname,
            static  => 0,
            virtual => 0,
            class   => $class,
            text    => '<p>Undocumented Function</p>',
        };
        $types{ $si->{type} }{$sname} = $si;
    }

    for my $type (qw/public private/) {
        $out .= "$type:\n";
        for my $sname ( sort keys %{ $types{$type} } ) {
            my $si      = $types{$type}{$sname};
            my @static  = $si->{static}  ? 'static'  : ();
            my @virtual = $si->{virtual} ? 'virtual' : ();

            my $fstr = join( ' ', @static, @virtual, $si->{rv}, "$sname(" );
            $fstr .= join( ', ', @{ $si->{params} } );
            $fstr .= ')';

            $out .= "/** \@fn $fstr\n";
            $out .= $si->{text} . "\n";
            $out .= _out_html_code( $sname, $sub_nodes->{$sname} );
            $out .= "*/\n";
            $out .= $fstr . ";\n\n";
        }
    }

    return $out;
}


sub _out_class_begin {
    my($pname, $pkg_short, $namespace, $fname, $inherit, $used, $ver, $rev, $pod_txt) = @_;

    if ( $pname eq '!main' ) {
        $pkg_short = $pname = "${fname}_main";
    }

    my $out = '';

    $out .= "namespace $namespace {\n" if $namespace;

    $out .= "\n/** \@class $pname\n\n";
    $out .= "\@version $ver" if $ver;
    $out .= " rev:$rev" if $rev;
    $out .= "\n\n";

    if ($used) {
        $out .= "\@section ${pkg_short}_USED_MODULES USED_MODULES\n";
        $out .= "<ul>\n";
        for my $uname ( sort keys %$used ) {
            $out .= "<li>$uname</li>\n";
        }
        $out .= "</ul>\n";
    }

    $out .= "$pod_txt\n*/\n\n";

    $out .= "class $pkg_short: public";
    $out .= " ::$inherit" if $inherit;
    $out .= " {\n\n";

    return $out;
}


sub _out_class_end {
    my($namespace) = @_;

    my $out = "};\n";
    $out .= "};\n" if $namespace;

    return $out;
}


sub _parse_pod {
    my($self, $doc, $fname) = @_;

    my $parser = Pod::POM->new();

    my $txt = '';
    my %subs;

    my $pod_tokens = $doc->find('PPI::Token::Pod');

    return '', \%subs unless $pod_tokens;

    no warnings qw(once);
    $PPI::Transform::Doxygen::POD::PREFIX = $fname;
    for my $tok ( @$pod_tokens ) {
        ( my $quoted = $tok->content() ) =~ s/(\@|\\|\%|#)/\\$1/g;
        my $pom = $parser->parse_text($quoted);
        _filter_head2( $pom, \%subs );
        $txt .= PPI::Transform::Doxygen::POD->print($pom);
    }

    return $txt, \%subs;
}


sub _filter_head2 {
    my($pom, $sub_ref) = @_;

    my $nodes = $pom->content();
    my $method_for = 0;
    for my $sn ( @$nodes ) {
        $sn = '' if $method_for;
        next unless $sn and $sn->type() =~ /^(?:head[1-4]|begin|item|over|pod|for)$/;
        if ( $sn->type() eq 'head2' and $sn->title() =~ /[\w:]+\s*\(.*\)/ ) {
            my $sinfo = _sub_extract( $sn->title() );
            if ($sinfo) {
                $sinfo->{text} = PPI::Transform::Doxygen::POD->print($sn->content());
                $sub_ref->{$sinfo->{name}} = $sinfo;
                $sn = '';
            }
        } elsif ( $sn->type() eq 'for' ) {
            if (
                $sn->type eq 'for'
                and
                $sn->format =~ /^(?:function|method|class_method)$/
            ) {
                $sn = '';
                $method_for = 1;
            }

        } else {
            _filter_head2($sn);
        }
    }
}


my $rx_name_parms = qr/\s*([\w:]+)\s*\(\s*([^\)]*)\s*\)$/;
sub _sub_extract {
    my($str) = @_;


    my($long, $params) = $str =~ /$rx_name_parms/;
    return unless $long;

    $str =~ s/$rx_name_parms//;

    my @parts = split(/\s+/, $str);

    my $rv = pop(@parts) || 'void';
    $rv =~ s/(\%|\@|\&)/\\$1/g;

    my $cat = pop(@parts) || '';

    my @params = _add_type($params);

    my @nparts = split( /::/, $long );
    my $name   = pop @nparts;
    my $class  = join( '::', @nparts ) || '!main';

    my $static = $cat eq 'function' || $cat eq 'class_method';
    my $type = $name =~ /^_/ ? 'private' : 'public';

    return {
        type   => $type,
        rv     => $rv,
        params => \@params,
        name   => $name,
        static => $static,
        class  => $class,
    };
}


sub _add_type {
    return unless my $params = shift;

    unless ( ref($params) ) {
        $params =~ s/\s//g;
        $params = [ split(/,/, $params) ];
    }

    return map {
        my @sig = $_ =~ /^(.)(.)(.?)/;
        if ( $sig[0] eq '\\' ) { shift @sig }
        my $ref;
        if ( $sig[1] eq '$' ) { $ref = 1; splice(@sig, 1, 1) }
        my $typ = $vtype{ $sig[0] };
        $typ .= '_ref' if $ref;
        s/^\W*//;
        $_ = "$typ $_";
    } @$params;
}


sub _find_first_regex {
    my($root, $name, $regex) = @_;
    for my $chld ( $root->schildren() ) {
        next unless $chld->isa($name);
        if ( my @capture = $chld->content() =~ /$regex/ ) {
            return @capture;
        }
    }
    return '';
}


sub _get_pkg_version {
    my($self, $root) = @_;
    my($version) = _find_first_regex(
        $root,
        'PPI::Statement::Variable',
        $self->{rx_version},
    );

    my($revision) = _find_first_regex(
        $root,
        'PPI::Statement::Variable',
        $self->{rx_revision},
    );
    return $version, $revision;
}


sub _out_html_code {
    my($sname, $sub) = @_;

    my $html = _strip(qq(
        \@htmlonly
        <div id='codesection-$sname' class='dynheader closed' style='cursor:pointer;' onclick='return toggleVisibility(this)'>
            <img id='codesection-$sname-trigger' src='closed.png' style='display:inline'><b>Code:</b>
        </div>
        <div id='codesection-$sname-summary' class='dyncontent' style='display:block;font-size:small;'>click to view</div>
        <div id='codesection-$sname-content' class='dyncontent' style='display: none;'>
        \@endhtmlonly
        \@code
    ));

    $html .= $sub;
    $html .= "\n";

    $html .= _strip(q(
        @endcode
        @htmlonly
        </div>
        @endhtmlonly
    ));

    return $html;
}


sub _sub_info_from_node {
    my($sname, $class, $node) = @_;

    return undef unless $node->class eq 'PPI::Statement::Sub';

    my $parser = Pod::POM->new();
    my %si;
    my $txt = my $def = '';
    my @params;
    my($rv, $static);
    my $type = $sname =~ /^_/ ? 'private' : 'public';

    my $pod = $node->find('PPI::Token::Pod') || [];
    for my $tok ( @$pod ) {
        ( my $quoted = $tok ) =~ s/(\@|\\|\%|#)/\\$1/g;
        my $pom = $parser->parse_text($quoted);
        next unless my $for = $pom->for->[0];
        $rv     = $for->text;
        $static = $for->format eq 'function' || $for->format eq 'class_method';
        $txt .= PPI::Transform::Doxygen::POD->print($pom);
    }
    my $proto = $node->find('PPI::Token::Prototype') || [];
    for my $tok ( @$proto ) {
        for my $pmt ( split(/,/, $tok->prototype) ) {
            my($attr, $default) = split(/=/, $pmt);
            push @params, $attr;
            next unless $default;
            $def .= "<p>Default value for $attr is $default.</p>\n";
        }
        @params = _add_type(\@params);
    }
    my @word_tok = $node->find('PPI::Token::Word');
    my $last;
    while ( my $tok = pop @word_tok ) {
        $last = "$tok";
        next unless $tok eq 'return';
    }

    return undef unless $txt;

    $txt .= "\n$def" if $def;

    return {
        type   => $type,
        rv     => $rv,
        params => \@params,
        name   => $sname,
        static => $static,
        class  => $class,
        text   => $txt,
    }
}


sub _integrate_sub_info {
    my($pkg_subs, $sub_info) = @_;

    my %si_by_name = map { $_ => $sub_info->{$_} } keys %$sub_info;

    my %look;
    for my $class ( keys %$pkg_subs ) {
        for my $subname ( keys %{ $pkg_subs->{$class}{subs} } ) {
            if ( $si_by_name{$subname} ) {
                # pod info exists
                $si_by_name{$subname}{class} = $class;
                $look{$subname} = 1;
                next;
            };
            my $si = _sub_info_from_node(
                $subname,
                $class,
                $pkg_subs->{$class}{subs}{$subname},
            );
            $sub_info->{$subname} = $si if $si;
            $look{$subname} = 1;
        }
    }

    for my $si ( values %$sub_info ) {
        next if $look{ $si->{name} };
        $si->{virtual} = 1;
        $pkg_subs->{$si->{class}}{subs}{$si->{name}}
            = '<p>virtual function or method</p>';
    }
}

1;

=pod

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=head1 REPOSITORY

L<https://github.com/tomk3003/ppi-transform-doxygen>

=head1 COPYRIGHT

Copyright 2016 Thomas Kratz.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
