package Muster::Hook::FieldSubst;
$Muster::Hook::FieldSubst::VERSION = '0.92';
=head1 NAME

Muster::Hook::FieldSubst - Muster hook for field substitution

=head1 VERSION

version 0.92

=head1 SYNOPSIS

  # CamelCase plugin name
  package Muster::Hook::FieldSubst;
  use Mojo::Base 'Muster::Hook';

=head1 DESCRIPTION

L<Muster::Hook::FieldSubst> does field substition;
that is, it replaces a "field macro" with the content of that field
(aka the meta-data for the Leaf).

The pattern for fields is "{{$I<fieldname>}}".

=cut

use Mojo::Base 'Muster::Hook';
use Muster::Hooks;
use Muster::LeafFile;
use YAML::Any;
use Text::NeatTemplate;

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
    $self->{_nt} = Text::NeatTemplate->new();

    $hookmaster->add_hook('fieldsubst' => sub {
            my %args = @_;

            return $self->process(%args);
        },
    );
    return $self;
} # register

=head2 process

Process (scan or modify) a leaf object.
In scanning phase, this will do simple substitutions of known meta-data
(for example, "page").
In assembly phase, it will do the same, but the contents of the Leaf meta-data will likely be more complete.

In either case, this expects the leaf meta-data to be populated.

  my $new_leaf = $self->process(%args);

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};

    my $content = $leaf->cooked();
    my $page = $leaf->pagename;

    # substitute {{$var}} variables (source-page)
    $content =~ s/(\\?)\{\{\$([-_\w:]+)\}\}/$self->get_field_value($1,$2,$leaf)/eg;

    # we can't get other pages' meta-data if we are scanning
    # because they haven't been added to the database yet
    if ($phase eq $Muster::Hooks::PHASE_BUILD)
    {
        # substitute {{$page#var}} variables (source-page)
        $content =~ s/(\\?)\{\{\$([-\w\/]+)#([-_\w:]+)\}\}/$self->get_other_page_field_value($1, $3,$leaf,$2)/eg;
    }

    $leaf->{cooked} = $content;
    return $leaf;
} # process

=head2 get_field_value

Get the field value for this page.

=cut
sub get_field_value {
    my $self = shift;
    my $escape = shift;
    my $field = shift;
    my $leaf = shift;

    if (length $escape)
    {
	return "{{\$${field}}}";
    }

    # force all fields to lower-case
    $field = lc($field);
    my ($varname, @formats) = split(':', $field);

    my $value = '';
    if ($varname eq 'page') # page is pagename
    {
        $value = $leaf->pagename;
    }
    elsif ($varname eq 'pagesrc')
    {
        $value = $leaf->pagesrcname;
    }
    elsif (exists $leaf->{meta}->{$varname})
    {
        $value = $leaf->{meta}->{$varname};
    }
    elsif (exists $leaf->{$varname})
    {
        $value = $leaf->{$varname};
    }
    if (!defined $value)
    {
        return '';
    }
    if (ref $value eq 'ARRAY')
    {
        $value = join('|', @{$value});
    }
    elsif (ref $value eq 'HASH')
    {
        $value = Dump($value);
    }

    # Format the value
    foreach my $format (@formats) { 
	$value = $self->{_nt}->convert_value(value=>$value,
	    format=>$format,
	    name=>$varname); 
    }
    return ($value ? $value : '');
} # get_field_value

=head2 get_other_page_field_value

Get the field value for a different page.

=cut
sub get_other_page_field_value {
    my $self = shift;
    my $escape = shift;
    my $field = shift;
    my $leaf = shift;
    my $other_page = shift;

    if (length $escape)
    {
	return "{{\$${other_page}#${field}}}";
    }

    # force all fields to lower-case
    $field = lc($field);
    my ($varname, @formats) = split(':', $field);

    my $value = '';
    my $use_page = $self->{metadb}->bestlink($leaf->pagename, $other_page);
    # $use_page will be blank if the page doesn't exist
    if ($use_page)
    {
        my $info = $self->{metadb}->page_or_file_info($use_page);
        if ($varname eq 'page') # page is pagename
        {
            $value = $info->{pagename};
        }
        elsif (exists $info->{$varname})
        {
            $value = $info->{$varname};
            if (ref $value eq 'ARRAY')
            {
                $value = join('|', @{$value});
            }
            elsif (ref $value eq 'HASH')
            {
                $value = Dump($value);
            }
        }
    }

    # Format the value
    foreach my $format (@formats) { 
	$value = $self->{_nt}->convert_value(value=>$value,
	    format=>$format,
	    name=>$varname); 
    }
    return ($value ? $value : '');
} # get_other_page_field_value

1;
