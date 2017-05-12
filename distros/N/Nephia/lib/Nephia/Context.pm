package Nephia::Context;
use strict;
use warnings;

sub new {
    my ($class, %opts) = @_;
    return bless {%opts}, $class;
}

sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

sub set {
    my ($self, $key, $val) = @_;
    return $self->{$key} = $val;
}

sub delete {
    my ($self, $key) = @_;
    delete $self->{$key};
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Context - Context Class for Nephia

=head1 DESCRIPTION

HASHREF plus alpha

=head1 SYNOPSIS

    my $context = Nephia::Context->new( foo => 'bar', hoge => [qw/fuga piyo/] );
    $context->get('foo');           ### 'bar'
    $context->get('hoge');          ### ['fuga', 'piyo'];
    $context->set(fizzbuzz => sub { 
        my $x = ''; 
        $x .= 'fizz' if ! $x % 3; 
        $x .= 'buzz' if ! $x % 5; 
        $x .= $_[0] unless $x; 
        return $x;
    });
    $context->delete('hoge');
    $context->get('hoge')           ### undef
    $context->get('fizzbuzz')->(12) ### 'fizz'

=head1 METHODS

=head2 new

    my $context = Nephia::Context->new( %items );

Instantiate Nephia::Context. Then, store specified items.

=head2 get

    my $item = $context->get( $name );

Fetch specified item that stored.

=head2 set

    $context->set( $name => $value );

Store specified item.

=head2 delete

    $context->delete( $name );

Delete a specified item.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

