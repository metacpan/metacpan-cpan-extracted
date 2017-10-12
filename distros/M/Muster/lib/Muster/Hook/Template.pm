package Muster::Hook::Template;
$Muster::Hook::Template::VERSION = '0.62';
=head1 NAME

Muster::Hook::Template - Muster template directive.

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::Template> for template directives inside pages.

=cut

use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;
use Muster::Hook::Links;
use File::Basename qw(basename);
use YAML::Any;
use Text::NeatTemplate;
use Math::Calc::Parser;

use Carp 'croak';

=head1 METHODS

L<Muster::Hook::Template> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{neat} = Text::NeatTemplate->new();

    $hookmaster->add_hook('template' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'template',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(directive=>'template',%args2);
                },
                %args,
            );
        },
    );
    return $self;
} # register

=head2 process

Process templates.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $directive = $args{directive};
    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my @p = @{$args{params}};
    my %params = @p;

    foreach my $wanted (qw(template))
    {
        if (! exists $params{$wanted})
        {
            return "ERROR: missing $wanted parameter";
        }
    }
    if ($phase eq $Muster::Hooks::PHASE_SCAN)
    {
        return "";
    }

    # fill in the template with the leaf's data
    my $result = $self->{neat}->fill_in(
        data_hash=>$leaf->{meta},
        template=>$params{template},
    );

    return $result;
} # process

# -------------------------------------------------------------
# Callable Functions for Text::NeatTemplate
# -------------------------------------------------------------

=head2 format_yaml

{&format_yaml(fieldname,yaml_value)}

Format a yaml field.

=cut
sub format_yaml {
    my $fieldname = shift;
    my $value = shift;

    # if they didn't give us anything, return
    if (!$value)
    {
	return '';
    }

    my $loaded = Load($value);
    if (!$loaded)
    {
        return $value;
    }
    if (!ref $loaded)
    {
        return $loaded;
    }

    my $out = '';
    if ($fieldname)
    {
        $out .= "<b>" . uc($fieldname) . ":</b>\n";
    }
    if (ref $loaded eq 'HASH')
    {
        $out .= _format_hash($loaded,0);
    }
    elsif (ref $loaded eq 'ARRAY')
    {
        $out .= _format_array($loaded,0);
    }
    $out .= "<br/>\n";
    return $out;
} # format_yaml

sub _format_hash {
    my $hash = shift;
    my $level = shift;

    my $out = '';
    foreach my $key (sort keys %{$hash})
    {
        if ($level == 0)
        {
            $out .= "<br/><b>$key:</b> ";
        }
        else
        {
            $out .= '<br/>' . '&nbsp;&nbsp;' x $level . $key . ': ';
        }

        my $v = $hash->{$key};
        if (!ref $v)
        {
            $out .= $v;
        }
        elsif (ref $v eq 'HASH')
        {
            $out .= _format_hash($v,$level + 1);
        }
        elsif (ref $v eq 'ARRAY')
        {
            $out .= _format_array($v,$level + 1);
        }
    }
    return $out;
} # _format_hash

sub _format_array {
    my $array = shift;
    my $level = shift;

    my $out = '';
    foreach my $item (@{$array})
    {
        if (!ref $item)
        {
            $out .= $item . "<br/>\n";
        }
        elsif (ref $item eq 'HASH')
        {
            $out .= _format_hash($item,$level + 1);
        }
        elsif (ref $item eq 'ARRAY')
        {
            $out .= _format_array($item,$level + 1);
        }
    }
    return $out;
} # _format_array

=head2 repeat_n

{&repeat_n(num,value)}

Repeat a format N times.
Simple substitution: $$N is the number
    and $$A is the equivalent letter.

=cut
sub repeat_n {
    my $num = shift;
    my @values = @_;

    my $value = join(',', @values);
    my @out = ();
    my $a = 'A';
    for (my $i = 1; $i <= $num; $i++)
    {
        my $line = $value;
        $line =~ s/\$\$N/$i/g;
        $line =~ s/\$\$A/$a/g;
        push @out, $line;
        $a++;
    }
    return join("", @out);
} # repeat_n

=head2 repeat_for

{&repeat_for(pipe_value,value)}

Repeat a format for each "pipe-value" (pipe-separated value).
Simple substitution:
    $$F is the "for" value
    $$N is the number
    and $$A is the equivalent letter.

=cut
sub repeat_for {
    my $pipeval = shift;
    my @values = @_;

    my @tags = split(/[|]/, $pipeval);
    my $value = join(',', @values);
    my @out = ();
    my $a = 'A';
    my $i = 1;
    foreach my $tag (@tags)
    {
        my $line = $value;
        $line =~ s/\$\$F/$tag/g;
        $line =~ s/\$\$N/$i/g;
        $line =~ s/\$\$A/$a/g;
        push @out, $line;
        $a++;
        $i++;
    }
    return join("", @out);
} # repeat_for

=head2 math

{&math(mathexpr)}

Do math with the given fields.

=cut
sub math {
    my $expression = shift;

    # if they didn't give us anything, return
    if (!$expression)
    {
	return '';
    }
    my $result = Math::Calc::Parser->evaluate($expression);

    return $result;
} # math

1;
