use strict;

package Tamino::Tran::Prepared;
use base qw/Class::Accessor Class::Data::Inheritable/;

__PACKAGE__->mk_ro_accessors(qw/tran handle/);

=head1 NAME

Tamino::Tran::Prepared - The L<Tamino> driver's class implementing prepared statements.

=head1 SYNOPSIS

    use Tamino;
    
    my $tamino_client = Tamino->new(
        server      => '127.0.0.1/tamino'
        db          => 'mydb'
    );
    
    # $t will be a Tamino::Tran object
    my $t = $tamino_client->begin_tran
        or die $tamino_client->error;
    
    my $stmt = $t->prepare(q{for $x in input()/xxx[@yyy=$y][zzz=$z]}, {
        y => 'string',
        z => 'xs:integer'
    }) or die $t->error;
    
    my $xml = $stmt->execute({
        y => 'asdf',
        z => 123
    }) or die $t->error;
    
    my $cursor = $stmt->open_cursor({
        y => 'asdf',
        z => 123
    }, fetch_size => 10) or die $t->error;
    
    $stmt->destroy;

=head1 DESCRIPTION

This is just an API wrapper.
This driver is based on L<LWP::UserAgent>, L<XML::Twig>, and inherits from L<Class::Accessor> and L<Class::Data::Inheritable>.

=cut

=head1 CONSTRUCTOR

Constructor is called internally by L<Tamino> class object.

=cut 

sub new ($$) {
    my $class = shift;
    my %args = @_;
    
    $args{query} =~ s/(^\s+|\s+$)//gs;
    $args{query} = join("\n", map {
            $args{vars}->{$_} =~ s/^\w+$/xs:$&/;
            sprintf('declare variable $%s as %s external',$_,$args{vars}->{$_})
        } keys %{$args{vars}}) . 
        "\n" . $args{query}
            if($args{vars});
            
    $class = ref $class || $class;
    my $self = $class->SUPER::new({
        tran  => $args{tran},
    });
    
    my $q = $self->tran->_cmd({ _prepare => $args{query} }, result => 'ino:query'); #send_session => 1 # This is probably needed...
    return unless $q;
    
    $self->{handle} = $q->att('ino:handle') or return;
    return $self;
}

=head1 METHODS

=head2 execute

    $xml = $stmt->execute(\%vars_values);
    $xml = $stmt->execute({ y => 'string', z => 123 }) or die $t->error;

Execute prepared statement

=cut

sub execute ($;$) {
    my ($self, $vars) = @_;
    return $self->tran->_cmd({ $vars?(map { '$'.$_ => $vars->{$_} } keys %$vars):(), _execute => 'prepared-xquery', _handle => $self->{handle} }, result => 'xq:result');
}

=head2 open_cursor

    $cur = $stmt->open_cursor(\%vars_values, %cursor_options);
    $cur = $stmt->open_cursor({ y => 'string', z => 123 }, fetch_size => 10, scrollable => 1) or die $t->error;

Execute prepared statement and open a cursor for resultset.
C<%cursor_options> are the same as for L<Tamino::Tran/xquery_cursor>.

=cut

sub open_cursor ($;$@) {
    my ($self, $vars, %cursor_opts) = @_;
    return $self->tran->_open_cursor({ $vars?(map { '$'.$_ => $vars->{$_} } keys %$vars):(),
        _execute => 'prepared-xquery',
        _handle => $self->{handle}
    },
        result => 'xq:result',
        (map { $_ => $cursor_opts{$_} } qw/scrollable vague fetch_size no_fetch/)
    );
}

=head2 destroy

    $stmt->destroy;

=cut

sub destroy ($) {
    my ($self) = @_;
    if($self->{handle} && defined $self->tran->_cmd({ _destroy => $self->{handle} })) {
        $self->{handle} = undef;
        return 1;
    }
    return 0;
}

sub DESTROY {
    $_[0]->destroy;
}

1;

