package ShipIt::Step::CheckVersionsMatch;

use strict;
use warnings;

use base 'ShipIt::Step';

use File::Find::Rule;


our $VERSION = '0.02';

sub run {
    my $self  = shift;
    my $state = shift;

    my $master_version = $state->version();

    for my $mod ( File::Find::Rule->name('*.pm')->in('lib') )
    {
        my $version = $self->_version_from_file($mod);
        next unless defined $version && length $version;

        if ( $version ne $master_version )
        {
            die "The version in $mod ($version) does not match the master version ($master_version)\n";
        }
    }
}

# Copied from ProjectType::Perl, which operates only on $self->{ver_from}
sub _version_from_file
{
    my $self = shift;
    my $file = shift;

    open my $fh, '<', $file
        or die "Failed to open $file: $!\n";

    while (<$fh>) {
        return $2 if /\$VERSION\s*=\s*([\'\"])(.+?)\1/;
    }
}


1;

__END__

=pod

=head1 NAME

ShipIt::Step::CheckVersionsMatch - Check that all modules with a $VERSION match

=head1 SYNOPSIS

  steps = FindVersion, ChangeVersion, CheckChangeLog, CheckVersionsMatch, DistTest, Tag, MakeDist

=head1 DESCRIPTION

So the Moose distribution, of which I'm a maintainer, has a
C<$VERSION> in every damn module (not my idea). This ShipIt step
checks to make sure that they all match.

=head1 AUTHOR

Dave Rolsky, C<< <autarch@urth.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-shipit-step-checkversionsmatch@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then
you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
