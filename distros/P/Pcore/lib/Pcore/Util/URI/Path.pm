package Pcore::Util::URI::Path;

use Pcore;
use base qw[Pcore::Util::Path];

use overload    #
  q[""] => sub {
    return $_[0]->to_uri;
  },
  q[cmp] => sub {
    return !$_[2] ? $_[0]->to_uri cmp $_[1] : $_[1] cmp $_[0]->to_uri;
  },
  q[~~] => sub {
    return !$_[2] ? $_[0]->to_uri ~~ $_[1] : $_[1] ~~ $_[0]->to_uri;
  },
  fallback => undef;

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::URI::Path

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
