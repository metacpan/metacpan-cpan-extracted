package SWF::Generator;
use strict;
use warnings;
our $VERSION = '0.011';

use Template;
use IPC::Run qw/run/;
use Encode;

sub new {
    my ( $class, %opt ) = @_;

    my $tmpl = Template->new($opt{tt_option}||{});

    return bless {
        _template       => $tmpl,
        _swfmill_option => $opt{swfmill_option} || [],
    }, $class;
}

sub process {
    my ($self, $input, $vars) = @_;

    $self->{_template}->process($input, $vars, \my $xml) or die $self->{_template}->error();
    $xml = encode('utf-8', $xml) if utf8::is_utf8($xml);

    my $err;
    run ['swfmill', @{$self->{_swfmill_option}}, qw/xml2swf stdin/], \$xml, \my $swf, \$err or die $err;

    return $swf;
}

1;
__END__

=head1 NAME

SWF::Generator - swf(adobe flash file) generator for perl5

=head1 SYNOPSIS

  use SWF::Generator;

  my $swfgen = SWF::Generator->new;
  my $swf = $swfgen->process('foo.xml');

  # setting swfmill and tt options
  my $swfgen = SWF::Generator->new(
                   swfmill_option => [qw/-e cp932/],
                   tt_option      => { INCLUDE_PATH => ['/tmp/'] },
               );
  my $swf = $swfgen->process('foo.xml');

  # setting vars
  my $xml = ".....<tags>[% buz %]</tags>";
  my $swfgen = SWF::Generator->new;
  my $swf = $swfgen->process(\$xml, { buz => 'bar' });


=head1 DESCRIPTION

SWF::Generator is swf generator for perl5.
this module use swfmill.

1) make xml
> swfmill swf2xml foo.swf > foo.xml

2) edit xml template
> vim foo.xml
 <tags>xxxxx</tags> => <tags>[% name %]</tags>

3) run SWF::Generator

my $sg = SWF::Generator->new;
print $sg->process('foo.xml', { name => 'bar' });

# => output swf binary.

=head1 AUTHOR

kan.fushihara {at} gmail.com

=head1 SEE ALSO

L<Template>, L<http://swfmill.org/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
