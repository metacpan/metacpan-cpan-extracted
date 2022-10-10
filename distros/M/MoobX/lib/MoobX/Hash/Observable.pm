package MoobX::Hash::Observable;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Observable role for MobX hashes
$MoobX::Hash::Observable::VERSION = '0.1.2';

use Moose::Role;

use experimental 'postderef', 'signatures';

use Scalar::Util 'refaddr';

before [ qw/ FETCH FIRSTKEY NEXTKEY EXISTS /] => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};


after [ qw/ STORE CLEAR DELETE /] => sub {
    my $self = shift;
    for my $i ( values $self->value->%* ) {
        next if tied $i;
        next unless ref $i;
        my $type = ref  $i;
        if( $type eq 'ARRAY' ) {
            MoobX::observable( @$i );
        }
        elsif( $type eq 'HASH' ) {
            MoobX::observable( %$i );
        }
    }
    MoobX::observable_modified( $self );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Hash::Observable - Observable role for MobX hashes

=head1 VERSION

version 0.1.2

=head1 DESCRIPTION

Role applied to L<MoobX::hash> objects to make them observables.

Used internally by L<MoobX>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
