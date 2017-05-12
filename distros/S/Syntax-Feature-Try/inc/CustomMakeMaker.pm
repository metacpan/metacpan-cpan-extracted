package inc::CustomMakeMaker;

use Moose;
use ExtUtils::Depends;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

around _build_WriteMakefile_args => sub {
    my ($orig, $self) = @_;

    my $args = $self->$orig();

    foreach my $key (qw/ TRY_PARSER_DEBUG TRY_PARSER_DUMP /) {
        next if not $ENV{$key};
        $args->{DEFINE} //= "";
        $args->{DEFINE} .= " -D$key";
    }

    $args->{INC} = ($args->{INC} || "") . " -Isrc";

    #use Data::Dumper; warn Dumper($args);
    return $args;
};

__PACKAGE__->meta->make_immutable;
