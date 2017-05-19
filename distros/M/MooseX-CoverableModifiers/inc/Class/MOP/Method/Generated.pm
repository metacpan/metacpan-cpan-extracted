#line 1

package Class::MOP::Method::Generated;
BEGIN {
  $Class::MOP::Method::Generated::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Method::Generated::VERSION = '2.0401';
}

use strict;
use warnings;

use Carp 'confess';
use Eval::Closure;

use base 'Class::MOP::Method';

## accessors

sub new {
    confess __PACKAGE__ . " is an abstract base class, you must provide a constructor.";
}

sub _initialize_body {
    confess "No body to initialize, " . __PACKAGE__ . " is an abstract base class";
}

sub _generate_description {
    my ( $self, $context ) = @_;
    $context ||= $self->definition_context;

    my $desc = "generated method";
    my $origin = "unknown origin";

    if (defined $context) {
        if (defined $context->{description}) {
            $desc = $context->{description};
        }

        if (defined $context->{file} || defined $context->{line}) {
            $origin = "defined at "
                    . (defined $context->{file}
                        ? $context->{file} : "<unknown file>")
                    . " line "
                    . (defined $context->{line}
                        ? $context->{line} : "<unknown line>");
        }
    }

    return "$desc ($origin)";
}

sub _compile_code {
    my ( $self, @args ) = @_;
    unshift @args, 'source' if @args % 2;
    my %args = @args;

    my $context = delete $args{context};
    my $environment = $self->can('_eval_environment')
        ? $self->_eval_environment
        : {};

    return eval_closure(
        environment => $environment,
        description => $self->_generate_description($context),
        %args,
    );
}

1;

# ABSTRACT: Abstract base class for generated methods



#line 105


__END__


