package MouseX::Types::Data::Monad;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";



1;
__END__

=encoding utf-8

=head1 NAME

MouseX::Types::Data::Monad - Mouse type constraints for Data::Monad

=head1 SYNOPSIS

    use Data::Monad::Either qw( right left );
    use Data::Monad::Maybe qw( just nothing );
    use MouseX::Types::Data::Monad::Either;
    use MouseX::Types::Data::Monad::Maybe;
    use Smart::Args qw( args );

    sub maybe_value_from_api {
      args my $json => 'MaybeM[HashRef]';
      $json->flat_map(sub {
        # ...
      });
    }

    maybe_value_from_api(just +{ ok => 1 });
    maybe_value_from_api(nothing);

    sub value_or_error_from_api {
      args my $json => 'Either[Left[Str] | Right[Int]]';
      $json->flat_map(sub {
        # ...
      });
    }

    value_or_error_from_api(right(1));
    value_or_error_from_api(left('some error'));

=head1 DESCRIPTION

MouseX::Types::Data::Monad provides L<Mouse> type constraints for Data::Monad family.

=head1 SEE ALSO

L<MouseX::Types::Data::Monad::Maybe>

L<MouseX::Types::Data::Monad::Either>

=head1 LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

