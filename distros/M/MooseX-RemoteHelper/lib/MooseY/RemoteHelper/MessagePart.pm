package MooseY::RemoteHelper::MessagePart;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.001021'; # VERSION

use Moose;
use MooseX::RemoteHelper;
use MooseX::UndefTolerant;
#use MooseX::Constructor::AllErrors;

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Base class for a part of a message
# SEEALSO:  MooseX::UndefTolerant, MooseX::Constructor::AllErrors

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseY::RemoteHelper::MessagePart - Base class for a part of a message

=head1 VERSION

version 0.001021

=head1 SYNOPSIS

	use Moose;
	extends 'MooseY::RemoteHelper::MessagePart';

=head1 DESCRIPTION

This is mostly useful for auto importing extensions which are sane when
dealing with remote APIs. Since I work with a lot of remote APIs I got tired
of writing this class.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/moosex-remotehelper/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::RemoteHelper|MooseX::RemoteHelper>

=item *

L<MooseX::UndefTolerant|MooseX::UndefTolerant>

=item *

L<MooseX::Constructor::AllErrors|MooseX::Constructor::AllErrors>

=back

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
