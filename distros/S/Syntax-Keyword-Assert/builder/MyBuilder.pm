package builder::MyBuilder;
use strict;
use warnings;
use base qw(Module::Build);

use XS::Parse::Keyword::Builder;

sub new {
    my ($class, %args) = @_;

    my $build = $class->SUPER::new(%args);

    my @flags = @{ $build->extra_compiler_flags };
    push @flags, XS::Parse::Keyword::Builder->extra_compiler_flags;

    $build->extra_compiler_flags( @flags );

    return $build;
}

sub ACTION_code {
    my ($self, @args) = @_;

    XS::Parse::Keyword::Builder->write_XSParseKeyword_h;

    $self->SUPER::ACTION_code(@args);
}

1;
