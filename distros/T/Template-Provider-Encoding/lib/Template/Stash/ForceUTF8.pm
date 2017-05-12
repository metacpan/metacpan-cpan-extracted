package Template::Stash::ForceUTF8;

use strict;
our $VERSION = '0.03';

use Template::Config;
use base ( $Template::Config::STASH );
use Encode;

sub get {
    my $self = shift;
    my $result = $self->SUPER::get(@_);
    return $result if ref $result;

    Encode::_utf8_on($result) unless Encode::is_utf8($result);
    return $result;
}

1;
__END__

=head1 NAME

Template::Stash::ForceUTF8 - Force UTF-8 (Unicode) flag on stash variables

=head1 SYNOPSIS

  use Template::Stash::ForceUTF8;
  use Template;

  my $tt = Template->new(
      LOAD_TEMPLATES => [ Template::Provider::Encoding->new ],
      STASH => Template::Stash::ForceUTF8->new,
  );

  my $vars;
  $vars->{foo} = "\x{5bae}\x{5ddd}";         # Unicode flagged
  $vars->{bar} = "\xe5\xae\xae\xe5\xb7\x9d"; # UTF-8 bytes

  $tt->process($template, $vars); # this DWIMs

=head1 DESCRIPTION

Template::Stash::ForceUTF8 is a Template::Stash that forces Unicode
flag on stash variables. Best used with L<Template::Provider::Encoding>.

=head1 SEE ALSO

L<Template::Provider::Encoding>

=cut
