package Muster::Hook::DynamicField;
$Muster::Hook::DynamicField::VERSION = '0.62';
=head1 NAME

Muster::Hook::DynamicField - Muster hook for dynamic fields

=head1 VERSION

version 0.62

=head1 SYNOPSIS

  # CamelCase plugin name
  package Muster::Hook::DynamicField;
  use Mojo::Base 'Muster::Hook';

=head1 DESCRIPTION

L<Muster::Hook::DynamicField> does dynamic fields:
field-substitution for derived values which are not always constant, such as the current date.

The pattern for dynamic fields is "{{!I<fieldname>}}".

=cut

use Mojo::Base 'Muster::Hook';
use Muster::Hooks;
use Muster::LeafFile;
use YAML::Any;
use POSIX qw(strftime);
use Math::Calc::Parser;
use Muster::Hook::Costings;

=head1 METHODS

=head2 register

Initialize, and register hooks.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    # we need to be able to look things up in the database
    $self->{metadb} = $hookmaster->{metadb};

    $hookmaster->add_hook('dynamicfield' => sub {
            my %args = @_;

            return $self->process(%args);
        },
    );
    return $self;
} # register

=head2 process

Process (modify) a leaf object.
In scanning phase, this will do nothing, because it's pointless.
In assembly phase, it will do simple substitutions of calculated data (which may or may not be derived from the leaf data).

  my $new_leaf = $self->process(%args);

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};

    if (!$leaf->is_page)
    {
        return $leaf;
    }
    if ($phase ne $Muster::Hooks::PHASE_BUILD)
    {
        return $leaf;
    }

    my $content = $leaf->cooked();
    my $page = $leaf->pagename;

    # substitute {{!var}} variables
    $content =~ s/(\\?)\{\{\!([-\w]+)\}\}/$self->get_dynamic_value($1,$2,$leaf)/eg;
    
    # substitute {{!fn(...)}} functions
    $content =~ s/(\\?)\{\{\!([-\w]+)\(([^)]+)\)\}\}/$self->get_function_result($1,$2,$3,$leaf)/eg;
    # substitute {{!fn[...]}} functions for functions that need parens as args
    $content =~ s/(\\?)\{\{\!([-\w]+)\[([^\]]+)\]\}\}/$self->get_function_result($1,$2,$3,$leaf)/eg;

    $leaf->{cooked} = $content;
    return $leaf;
} # process

=head2 get_dynamic_value

Get the dynamic value for this page.

=cut
sub get_dynamic_value {
    my $self = shift;
    my $escape = shift;
    my $field = shift;
    my $leaf = shift;

    if (length $escape)
    {
	return "{{\!${field}}}";
    }

    # force all fields to lower-case
    $field = lc($field);

    my $value;

    if ($field eq 'now')
    {
        $value = strftime '%H:%M:%S', localtime;
    }
    elsif ($field eq 'today')
    {
        $value = strftime '%Y-%m-%d', localtime;
    }
    elsif ($field eq 'thisyear')
    {
        $value = strftime '%Y', localtime;
    }


    if (!defined $value)
    {
        return '';
    }
    if (ref $value eq 'ARRAY')
    {
        $value = join(' ', @{$value});
    }
    elsif (ref $value eq 'HASH')
    {
        $value = Dump($value);
    }
    return $value;
} # get_dynamic_value

=head2 get_function_result

Process the given function for this page.

=cut
sub get_function_result {
    my $self = shift;
    my $escape = shift;
    my $func = shift;
    my $argvals = shift;
    my $leaf = shift;

    if (length $escape)
    {
	return "{{\!${func}(${argvals})}}";
    }

    my $value;

    if ($func eq 'math')
    {
        my $result = Math::Calc::Parser->evaluate($argvals);
        # round the result for niceness
        $value = sprintf("%.2f",$result);
    }
    elsif ($func eq 'matheq')
    {
        my $result = Math::Calc::Parser->evaluate($argvals);
        $value = "${argvals} = ${result}";
    }
    elsif ($func eq 'dyncost')
    {
        # dyncost(per_hour)
        if ($leaf->{meta}->{labour_time}
                or $leaf->{meta}->{materials_cost})
        {
            my $cost_per_hour = $argvals;
            my $labour_cost = ($leaf->{meta}->{labour_time} / 60) * $cost_per_hour;
            my $itemize_cost = ($leaf->{meta}->{itemize_time} / 60) * $cost_per_hour;
            my $wholesale = $leaf->{meta}->{materials_cost} + $labour_cost + $itemize_cost;
            my $overheads = Muster::Hook::Costings::calculate_overheads($wholesale);
            my $retail = $wholesale + $overheads;
            $value = "dyncost($cost_per_hour) = $retail";
        }
    }

    if (!defined $value)
    {
        return '';
    }
    if (ref $value eq 'ARRAY')
    {
        $value = join(' ', @{$value});
    }
    elsif (ref $value eq 'HASH')
    {
        $value = Dump($value);
    }
    return $value;
} # get_function_result


1;
