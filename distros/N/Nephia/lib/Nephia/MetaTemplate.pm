package Nephia::MetaTemplate;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite (
    new => 0,
    rw  => [qw[tag argument arrow oneliner replace_table]],
);

sub new {
    my ($class, %opts) = @_;
    $opts{tag}      ||= '<?= ... ?>';
    $opts{arrow}    ||= '}->{';
    $opts{argument} ||= '$arg->{...}';
    $opts{replace_table} ||= [qr|^| => '? my $arg = shift;'."\n"];
    bless +{%opts}, $class;
}

sub process {
    my ($self, $instr) = @_;
    my $str = $instr;
    for my $tag ( ($str =~ m|(\[\= .*? \=\])|g) ) {
        my ($content) = $tag =~ m|\[\= (.*?) \=\]|;
        my $raw_content = $content;
        my $arrow = $self->{arrow};
        $content =~ s|\.|$arrow|g;
        my $argument = $self->{argument};
        $argument =~ s|\.\.\.|$content|;
        my $replace = $self->{tag};
        $replace =~ s|\.\.\.|$argument|;
        $str =~ s|\[\= $raw_content \=\]|$replace|;
    }
    while ( $self->{replace_table}[0] && $self->{replace_table}[1] ) {
        my $search = shift(@{$self->{replace_table}});
        my $replace = shift(@{$self->{replace_table}});
        $str =~ s|$search|$replace|;
    }
    return $str;
}

1;

=head1 NAME

Nephia::MetaTemplate - Meta Template Processor for Nephia::Setup flavors

=head1 SYNOPSIS

A template in your flavor.

    <html>
    <head>
    <title>[= title =]</title>
    </head>
    </html>
    <body>
      <h1>Access to value: [= title =]</h1>
      <h2>Access to nested value: [= author.name =]</h2>
    </body>
    </html>

And, in your flavor class.

    my $meta_template = '<html>...'; # meta template string
    my $mt = Nephia::MetaTemplate->new(
        tag           => '{{ ... }}',
        arrow         => '@',
        argument      => 'val:...',
        replace_table => [
            qr|</body>| => '</body><script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>',
        ],
    );
    my $template = $mt->process($meta_template);

Then, $template is like as following.

    <html>
    <head>
    <title>{{ val:title }}</title>
    </head>
    </html>
    <body>
      <h1>Access to value: {{ val:title }}</h1>
      <h2>Access to nested value: {{ val:author@name }}</h2>
    </body><script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    </html>

=head1 DESCRIPTION

Nephia::MetaTemplate is a Meta-Template Processor for helping you make your own nephia flavor.

=head1 AUTHOR

C<ytnobody> E<lt>ytnobody@gmail.comE<gt>

=cut
