package Test::CallCounter;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.04';

use Scalar::Util 1.24 qw(set_prototype);
use Class::Method::Modifiers qw(install_modifier);

our $COUNTER;

sub new {
    my ($class, $klass, $method) = @_;

    my $self = bless +{
        class  => $klass,
        method => $method,
        count  => 0,
    }, $class;

    my $prototype = prototype($klass->can($method));

    install_modifier(
        $klass, 'before', $method, sub {
            $self->{count}++
        }
    );

    if (defined $prototype) {
        &set_prototype($klass->can($method), $prototype);
    }

    return $self;
}

sub count { $_[0]->{count} }
sub reset { $_[0]->{count} = 0 }

1;
__END__

=encoding utf8

=head1 NAME

Test::CallCounter - Count the number of method calling

=head1 SYNOPSIS

    use Test::CallCounter;

    my $counter = Test::CallCounter->new(
        'LWP::UserAgent' => 'get'
    );

    my $ua = LWP::UserAgent->new();
    $ua->get('http://d.hatena.ne.jp/');

    is($counter->count(), 1);

=head1 DESCRIPTION

Test::CallCounter counts the number of method calling.

=head1 METHODS

=over 4

=item my $counter = Test::CallCounter->new($class_name, $method_name)

Make a instance of Test::CallCounter and hook C<< $method_name >> method in C<< $class_name >> to count calling method.

=item $counter->count();

Get a calling count of C<< $method_name >>.

=item $counter->reset()

Reset counter.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Test::Mock::Guard>

If you want to do more complex operation while monkey patching, see also L<Test::Resub>.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
