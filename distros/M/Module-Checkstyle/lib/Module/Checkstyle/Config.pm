package Module::Checkstyle::Config;

use strict;
use warnings;
use Carp qw(croak);
use File::HomeDir;

use base qw(Config::Tiny);

sub new {
    my ($class, $file) = @_;

    # If we pass a Module::Checkstyle::Config object
    # we make that our config instead of cloning it.
    if (defined $file) {
        if (UNIVERSAL::isa($file, 'Module::Checkstyle::Config')) {
            return $file;
        }
    }
    
    # Resort to user-default config
    if (!defined $file) {
        $file = File::Spec->catfile(home(), '.module-checkstyle', 'config');
    }

    # Load the config or bail out
    my ($self, $name);
    if (ref $file eq 'GLOB') {
        my $config = join("", <$file>);
        $self = $class->SUPER::read_string($config);
    }
    elsif(ref $file eq 'SCALAR') {
        $self = $class->SUPER::read_string($$file);
    }
    elsif($file && -e $file && -f $file) {
        $self = $class->SUPER::read($file);
        $name = $file;
    }
    else {
        $self = $class->SUPER::new();        
    }

    if (!defined $self) {
        croak 'Failed to load config';
    }
    
    $self->{_}->{'_config-path'} = $name;
    if (!exists $self->{_}->{'global-error-level'} || $self->{_}->{'global-error-level'} !~ /^cricial|error|info|warn$/) {
        $self->{_}->{'global-error-level'} = 'warn';
    }

    $self->_fix();
    return $self;
}

sub _fix {
    my $self = shift;

  FIX_PROPERTIES:
    foreach my $section (keys %{$self}) {
        next FIX_PROPERTIES if $section eq '_';
        foreach my $property (keys %{$self->{$section}}) {
            if ($self->{$section}->{$property} =~ m/^ \s* (?:(critical|error|info|warn)\s+)? (.*?) $/ix) {
                $self->{_}->{_level}->{$section}->{$property} = $1;
                $self->{$section}->{$property} = $2;
            }
        }
    }
}

sub _get_check_and_property {
    my ($self, $check, $property) = @_;

    if (defined $check && !defined $property) {
        $property = $check;
        my $caller = caller(1);
        ($check) = $caller =~ m/^Module::Checkstyle::Check::(.*?)$/;
    }

    if (!defined $check) {
        croak "Can't determine check";
    }
    if (!defined $property) {
        croak "Can't determine property";
    }

    return ($self, $check, $property);
}

sub get_enabled_sections {
    my ($self) = @_;
    my @sections =  grep { $_ ne '_' } keys %$self;
    return @sections;
}

sub get_severity {
    my ($self, $check, $property) = &_get_check_and_property;

    my $level = $self->{_}->{_level}->{$check}->{$property};
    return $level || $self->get_directive('_', 'global-error-level');
}

sub get_directive {
    my ($self, $check, $property) = &_get_check_and_property;
    return $self->{$check}->{$property};
}

1;
__END__

=head1 NAME

Module::Checkstyle::Config - Handles configuration directives

=head1 SYNOPSIS
    
    use Module::Checkstyle::Config;
    my $config = Module::Checkstyle::Config->new();
    my $value = $config->get_directive('max-per-file');

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new (I<$source>)

Constructs a new C<Module::Checkstyle::Config> object. The optional argument C<$source> can be either
a reference to a GLOB as in C<new(\*DATA)>, a reference to a scalar containing the configuration C<new(\$config)>
or a scalar containing a path to a configuration file.

If the C<$source> is ommited it will look for the configuration file located at I<~/.module-checkstyle/config>.

=item get_enabled_sections

Returns a list of enabled sections.

=item get_severity (I<$check, > $directive)

Returns the severity level for a given directive specified by C<$directive> in the section specified by C<$check>. If C<$check> is ommited it will try to figure out what section to read from by investigating the callers package and removing C<Module::Checkstyle::Check>.

=item get_directive (I<$check, > $directive)

Returns a the directive specified by C<$directive> in the section specified by C<$check>. If C<$check> is
ommited it will try to figure out what section to read from by investigating the callers package and
removing C<Module::Checkstyle::Check>.

=back

=begin PRIVATE

=over 4

=item _fix

Traverses the config and extracts severity levels.

=item _get_check_and_property

Investigates to see if we need to figure out the check by checking caller.

=back

=end PRIVATE

=head1 FORMAT

Module::Checkstyle uses the INI file-format for its configuration file. The following 
example illustrates a sample config file:

 ; this is a sample config
 global-error-level = warn

 [Whitespace]
 after-comma     = true
 after-fat-comma = true

 [Package]
 max-per-file    = 1

Here we have a global configuration diretive, I<global-error-level>, and a few directives
applicable to a specified check.

=head2 SEVERITY

The directive I<global-error-level> sets the severity of a style violation. If it's ommited it will
default to 'warn'.

It is however possible to specify the severity on a per-config basis by prefixing the directives
value with either 'warn' or 'error' as in C<matches-name = error qr/\w+/>.

=head2 BOOLEAN DIRECTIVES

Some checks expect a boolean value when they read their config. Acceptable booleans are 1, y, yes and true.

=head2 REGEXP DIRECTIVES

Checks that matches names such as variable name or subroutine names expect a regular expression in the config.

To specify a regular expression the recommended way is to use the 'qr' operator as in C<matches-name = qr/\w+/>.
If you don't want to use another delimiter it is acceptable to specify the regular expression without 'qr' and
using // as in C<matches-name = /\w+/>.

=head1 SEE ALSO

L<Config::Tiny>
L<Module::Checkstyle>

=cut
