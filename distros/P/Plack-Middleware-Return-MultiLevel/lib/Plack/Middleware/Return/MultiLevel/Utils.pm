use strict;
use warnings;

package Plack::Middleware::Return::MultiLevel::Utils;

use Scalar::Util;
use Exporter 'import';
use Plack::Middleware::Return::MultiLevel;

our @EXPORT_OK = qw(return_to_level return_to_default_level);

sub return_to_level {
  my ($proto, $level_name, @returning) = @_;
  my $env = Scalar::Util::blessed($proto) ? $proto->env : $proto;
  return Plack::Middleware::Return::MultiLevel::_return_level(
    $env, $level_name, @returning);
}

sub return_to_default_level {
  return return_to_level(shift, Plack::Middleware::Return::MultiLevel::DEFAULT_LEVEL_NAME, @_);
}


=head1 TITLE
 
Plack::Middleware::Return::MultiLevel::Utils - Ease of Use Utility subroutines

=head1 SYNOPSIS

    use Plack::Middleware::Return::MultiLevel::Utils
      qw/return_to_level return_to_default_level/;

    return_to_default_level($env,
      [200, ['Content-Type', 'text/plain'], ['default']]);

    return_to_level($env, 'set_level_name',
      [200, ['Content-Type', 'text/plain'], ['named level']]);

=head1 DESCRIPTION

Ideally you'd invoke your L<Return::MultiLevel> return points via one if these
importable subroutines, rather than reaching into the C<psgi_env> hash.  This
gives you better encapsulation and allows the underlying code to change without
busted your use.

=head1 EXPORTS

This class defines the following exportable subroutines

=head2 return_to_default_level

    return_to_default_level($env,
      [200, ['Content-Type', 'text/plain'], ['default']]);

Requires C<$psgi_env> and a response, which typically is a PSGI type response,
athough you can return anything you want if there is middleware to convert it to
an acceptable PSGI style response, for example.

This can also be imported and called as a method on an object that does the C<env>
method. For example:

    $catalyst_context->request->return_to_default_level(\@response);

=head2 return_to_level

    return_to_level($env, 'set_level_name',
      [200, ['Content-Type', 'text/plain'], ['named level']]);

Just like L</return_to_default_level> except that the second argument is the name of a
return level that you set.  Also can be called as a method against an object that
does C<env>.
 
=head1 AUTHOR
 
See L<Plack::Middleware::Return::MultiLevel>

=head1 SEE ALSO

L<Plack::Middleware::Return::MultiLevel>
 
=head1 COPYRIGHT & LICENSE
 
See L<Plack::Middleware::Return::MultiLevel>

=cut

1;
