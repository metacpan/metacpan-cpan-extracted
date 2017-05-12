package Net::Kubernetes::Exception;
# ABSTRACT: Base class for all kubernetes exceptions.
$Net::Kubernetes::Exception::VERSION = '1.03';
use Moose;

extends "Throwable::Error";

has code => (
	is       => 'ro',
	isa      => 'Num',
	required => 0,
);

use Moose::Util::TypeConstraints;

subtype 'Net::Kubernetes::Exception::ClientException', as 'Net::Kubernetes::Exception', where {! defined $_->code};

subtype 'Net::Kubernetes::Exception::NotFound', as 'Net::Kubernetes::Exception', where { $_->code == 404 };

subtype 'Net::Kubernetes::Exception::Conflict', as 'Net::Kubernetes::Exception', where { $_->code == 409 };

subtype 'Net::Kubernetes::Exception::BadRequest', as 'Net::Kubernetes::Exception', where { $_->code == 400 };

no Moose::Util::TypeConstraints;


package Net::Kunbernetes::Exception::ClientException;
# ABSTRACT: Exception class for client side errors
$Net::Kunbernetes::Exception::ClientException::VERSION = '1.03';
require Net::Kubernetes::Exception;
use Moose;

extends 'Net::Kubernetes::Exception';
extends 'Throwable::Error';


package Net::Kunbernetes::Exception::NotFound;
# ABSTRACT: Kubernetes Not found exception (code 404)
$Net::Kunbernetes::Exception::NotFound::VERSION = '1.03';
require Net::Kubernetes::Exception;
use Moose;

extends 'Net::Kubernetes::Exception';
extends 'Throwable::Error';

package Net::Kunbernetes::Exception::Conflict;
# ABSTRACT: Kubernetes 'Conflict' exception (code 409)
$Net::Kunbernetes::Exception::Conflict::VERSION = '1.03';
require Net::Kubernetes::Exception;
use Moose;

extends 'Net::Kubernetes::Exception';
extends 'Throwable::Error';

package Net::Kunbernetes::Exception::BadRequest;
# ABSTRACT: Kubernetes 'Bad Request' exception (code 400)
$Net::Kunbernetes::Exception::BadRequest::VERSION = '1.03';
require Net::Kubernetes::Exception;
use Moose;

extends 'Net::Kubernetes::Exception';
extends 'Throwable::Error';

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Exception - Base class for all kubernetes exceptions.

=head1 VERSION

version 1.03

=head1 AUTHOR

Dave Mueller <dave@perljedi.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Mueller.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::Kubernetes|Net::Kubernetes>

=back

=cut
