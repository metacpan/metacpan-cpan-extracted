package Test::Cukes::Scenario;
use Any::Moose;

has name => (
    is => "rw",
    required => 1,
    isa => "Str"
);

has steps => (
    is => "rw",
    required => 1,
    isa => "ArrayRef[Str]"
);

sub BUILDARGS {
    my $class = shift;
    if (@_ == 1 && ! ref $_[0]) {
        my $scenario_text = shift;
        my $args = {
            name => "",
            steps => []
        };

        for my $line (split /\n+/, $scenario_text) {
            if ($line =~ /^Scenario:\s(.+)$/) {
                $args->{name} = $1;
            } elsif ($line =~ /^  (Given|When|Then|And)\s(.+)$/) {
                push @{$args->{ steps }}, "$1 $2";
            }
        }

        return $args;
    }

    return $class->SUPER::BUILDARGS(@_);
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
