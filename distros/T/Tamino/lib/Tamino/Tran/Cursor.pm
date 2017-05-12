use strict;

package Tamino::Tran::Cursor;
use base qw/Class::Accessor Class::Data::Inheritable/;

=head1 NAME

Tamino::Tran::Cursor - The L<Tamino> driver's class implementing cursors.

=head1 SYNOPSIS

    use Tamino;
    
    my $tamino_client = Tamino->new(
        server      => '127.0.0.1/tamino'
        db          => 'mydb'
    );
    
    # $t will be a Tamino::Tran object                                 
    my $t = $tamino_client->begin_tran
        or die $tamino_client->error;
    
    $c = $t->xquery_cursor(q{
        for $x in collection('mycollection')/doctype/xxx[@yyy=%s][zzz='%s']
        return $x
    }, "('y1','y2')", "z1") or die $t->error;

    while($xml_bare_simple_tree = $c->fetch) {
        print XML::Simple::XMLout($xml_bare_simple_tree, KeyAttr => []);
    }
    
    $c->close;

=head1 DESCRIPTION

This is just an API wrapper.
This driver is based on L<LWP::UserAgent>, L<XML::Twig>, and inherits from L<Class::Accessor> and L<Class::Data::Inheritable>.

=cut

__PACKAGE__->mk_classdata($_) for qw/fetch_size/;
__PACKAGE__->mk_ro_accessors(qw/tran handle scrollable vague result/);
__PACKAGE__->mk_accessors(qw/fetch_size _prefetched _pos error/);

__PACKAGE__->fetch_size(8);

=head1 CONSTRUCTOR

Constructor is called internally by L<Tamino::Tran> class object.

=cut

sub new ($@) {
    my $class = shift;
    my %args = @_;
      
    my $data = delete $args{data} or return;
                  
    $class = ref $class || $class;
    my $self = $class->SUPER::new({
        tran        => $args{tran},
        scrollable  => !!$args{scrollable},
        vague       => !!$args{vague},
        fetch_size  => $args{fetch_size} || __PACKAGE__->fetch_size,
        result      => $args{result},
    });
    
    $data->{_cursor} = 'open';
    $data->{_scroll} = $args{scrollable} ? 'yes' : 'no';
    $data->{_sensitive} = $args{vague} ? 'vague' : 'no';
    
    $self->{_pos} = $args{pos} || 1;
    unless($args{no_fetch}) {
        $data->{_position} = $self->{_pos};
        $data->{_quantity} = $self->{fetch_size};
    }
    
    my $q = $self->tran->_cmd($data, result => $self->{result}, _twig_handlers => {
        'ino:cursor' => sub {
            my ($twig,$cur) = @_;
            $self->{handle} = $cur->{'ino:handle'};
            $self->_get_pos($cur);
            1;
        }
    });
    return unless defined $q;
    
    $self->{_prefetched} = $q unless($args{no_fetch});
    return unless($q && $self->{handle});
    return $self;
}

=head1 METHODS

=head2 close

    $c->close;

Close cursor

=cut

sub close ($) {
    my ($self) = @_;
    if($self->{handle} && defined $self->tran->_cmd({_cursor => 'close', _handle => $self->{handle}})) {
        $self->{handle} = undef;
        return 1;
    }
    return 0;
}

=head2 fetch

    $xml = $c->fetch();
    $xml = $c->fetch($num);
    $xml = $c->fetch($num, $pos);

Fetch $num number of records from a cursor, startings from $pos position.
If $pos is omitted, fetch from current position.
If $num is omiited, fetch default number of records, which is set with C<< $c->fetch_size($num) >>

=cut

sub fetch ($;$$) {
    my ($self, $n, $pos) = @_;
    if(my $r = $self->{_prefetched}) {
        $self->{_prefetched} = undef;
        return $r;
    }
    return unless defined $self->{_pos};
    return $self->tran->_cmd({
            _cursor => 'fetch',
            _handle => $self->{handle},
            _position => $pos || $self->{_pos},
            _quantity => $n || $self->{fetch_size},
        },
        result => $self->result,
        _twig_handlers => {
            'ino:cursor' => sub {
                my ($twig,$cur) = @_;
                return 1 if($cur->{'ino:handle'} != $self->{handle}); # FIXME
                $self->_get_pos($cur);
                1;
            }
        }
    );
}

sub _get_pos ($$) {
    my ($self, $cur) = @_;
    if(exists $cur->{'ino:next'}) {
        $self->{_pos} = $cur->{'ino:next'}->{'ino:position'};
    } else {
        $self->tran->error("No more data");
        $self->{_pos} = undef;
    }
}

sub DESTROY {
    $_[0]->close;
}

=head2 fetch_size

    Tamino::Tran::Cursor->fetch_size($num);
    $c->fetch_size($num);

=cut

1;

