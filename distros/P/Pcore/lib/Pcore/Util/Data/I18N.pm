package Pcore::Util::Data::I18N;

use Pcore -class;
use overload    #
  q[""] => sub {
    return i18n( $_[0]->args->@* );
  },
  fallback => undef;

has args => ( is => 'ro', isa => ArrayRef, required => 1 );

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Data::I18N

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
