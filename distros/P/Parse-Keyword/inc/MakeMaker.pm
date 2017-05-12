package inc::MakeMaker;
use Moose;
use inc::MMHelper;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

around _build_MakeFile_PL_template => sub {
    my $orig = shift;
    my $self = shift;
    my $tmpl = $self->$orig;
    my $extra = inc::MMHelper::makefile_pl_extra;
    $tmpl =~ s/^(WriteMakefile\()/$extra\n$1/m
        or die "Couldn't fix template";
    return $tmpl;
};

around _build_WriteMakefile_args => sub {
    my $orig = shift;
    my $self = shift;
    my $args = $self->$orig(@_);
    return {
        %$args,
        %{ inc::MMHelper::mm_args() },
    }
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
