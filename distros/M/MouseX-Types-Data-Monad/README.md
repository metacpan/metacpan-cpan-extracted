[![Build Status](https://travis-ci.org/aereal/MouseX-Types-Data-Monad.svg?branch=master)](https://travis-ci.org/aereal/MouseX-Types-Data-Monad) [![Coverage Status](https://img.shields.io/coveralls/aereal/MouseX-Types-Data-Monad/master.svg)](https://coveralls.io/r/aereal/MouseX-Types-Data-Monad?branch=master)
# NAME

MouseX::Types::Data::Monad - Mouse type constraints for Data::Monad

# SYNOPSIS

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

# DESCRIPTION

MouseX::Types::Data::Monad provides [Mouse](https://metacpan.org/pod/Mouse) type constraints for Data::Monad family.

# SEE ALSO

[MouseX::Types::Data::Monad::Maybe](https://metacpan.org/pod/MouseX::Types::Data::Monad::Maybe)

[MouseX::Types::Data::Monad::Either](https://metacpan.org/pod/MouseX::Types::Data::Monad::Either)

# LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

aereal <aereal@aereal.org>
