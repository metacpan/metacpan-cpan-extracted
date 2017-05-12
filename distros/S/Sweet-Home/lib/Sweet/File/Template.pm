package Sweet::File::Template;
use latest;
use Moose;

use Carp;
use MooseX::AttributeShortcuts;
use MooseX::Types::Path::Class;
use Sweet::Types;
use Template;

use namespace::autoclean;

extends 'Sweet::File';

has output => (
    default => sub { '' },
    init_arg => undef,
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has include_path => (
    coerce => 1,
    is  => 'lazy',
    isa => 'Path::Class::Dir',
);

has _template => (
    builder => '_build_template',
    is      => 'lazy',
    isa     => 'Template'
);


sub _build_template {
    my $self = shift;

    my $config = $self->_template_config;

    my $template = Template->new($config)
      or die $Template::ERROR, "\n";

    return $template;
}

has _template_config => (
    builder => '_build_template_config',
    is      => 'ro',
    isa     => 'HashRef',
    lazy =>1,
);

sub _build_template_config {
    my $self = shift;

    my $include_path = $self->include_path;

    my $config = {
        INCLUDE_PATH => $include_path,
        POST_CHOMP => 1
    };

    return $config;
}

has template_name => (
    is      => 'lazy',
    isa     => 'Str'
);

sub _build_template_name { {} }

has template_vars => (
    is      => 'lazy',
    isa     => 'HashRef'
);

sub _build_template_vars { {} }

sub generate {
    my $self = shift;

    $self->process;
    $self->write;
}

sub _build_lines {
    my $self = shift;

    my $output = $self->output;

    my @lines = split "\n", $output;

    return \@lines;
}

use Data::Dumper;
sub process {
    my $self = shift;

    my $template      = $self->_template;
    my $output = $self->output;
    my $template_name = $self->template_name;
    my $template_vars = $self->template_vars;

    say Dumper($template_vars);
    $template->process( $template_name, $template_vars, \$output )
      or die $Template::ERROR, "\n";

  $self->output($output);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Sweet::File::Template;

=head1 SYNOPSIS

    use Sweet::File::Template;

    my $template = Sweet::File::Template->new(
        dir => '/path/to/dir',
        name => 'foo',
        template_name => 'foo.tpl',
        include_path => /path/to/template/dir'
    );

    $template->generate;

=head1 ATTRIBUTES

=head2 include_path

=head2 output

=head2 template_name

=head2 template_vars

=head1 PRIVATE ATTRIBUTES

=head2 _template

=head2 _template_config

=head1 METHODS

=head2 generate

Is a shortcut for

    $template->process;
    $template->write;

=head2 process

=cut

