package Pod::Elemental::Transformer::ExampleRunner;
BEGIN {
  $Pod::Elemental::Transformer::ExampleRunner::VERSION = '0.002';
}
# ABSTRACT: include/run examples scripts in your documentation without copy/paste
use Moose;
use Pod::Elemental::Transformer 0.101620;
    with 'Pod::Elemental::Transformer';



use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Types qw(FormatName);

use namespace::autoclean;

has format_name => (
  is  => 'ro',
  isa => FormatName,
  default => 'example',
);
has command => (
  is  => 'rw',
  isa => 'Str',
  default => 'example'
);

has script_path => (
    is => 'ro',
    isa => 'Str',
    default => './example/'
);


has debug => (
    is => 'rw', 
    default => sub { sub {} } 
);

has indent => (
    is => 'ro',
    isa => 'Str',
    default => '  ',
);

sub transform_node {
  my ($self, $doc) = @_;
  use Data::Dumper;

  for my $i (reverse(0 .. $#{ $doc->children })) {
    my $node = $doc->children->[ $i ];
    next unless $node->isa('Pod::Elemental::Element::Generic::Command')
                and $node->{command} eq $self->command
                ;

    my ($command, $subcommand) = split ' ', $node->{'content'}, 2;

    $self->debug->("going to $command with $subcommand on ".Dumper $node);
    my @replacements;
    if (my $action = $self->can("_$command") ) { 
        @replacements = $self->$action( $node,  $subcommand )
    }
    splice @{ $doc->children }, $i, 1, @replacements;
 }
}

sub _run {
    my ($self, $node, $subcommand) = @_;
    my ($filename, @args) = split ' ', $subcommand;
    my $path   = $self->script_path . $filename;

    open my $read, '-|', $path, @args 
        or return Pod::Elemental::Element::Generic::Nonpod->new({
            content => "# Couldn't run $path: $!\n\n"
        });
    my $output = do {local $/; <$read>; };
    close $read;
    my $exit   = $? >> 8;
    $output    = $self->indent_text_in($output);
    local $" = ' ';
    chomp $output;
    my $end = '.';
    $end = "# $filename exited with $exit" if $exit;

    Pod::Elemental::Element::Pod5::Verbatim->new({
        content => "#running $path @args\n\n$output\n\n#$end"
    });

}

sub _source {
    my ($self, $node, $subcommand) = @_;
    my ($filename, @args) = split ' ', $subcommand;
    my $path   = $self->script_path . $filename;
    my $source = do {
        local (@ARGV,$/) = $path;
        <>
    };
    $source = $self->remove_yadas_from($source);
    $source = $self->indent_text_in($source);
    chomp $source;
    Pod::Elemental::Element::Pod5::Verbatim->new({
        content => "#see $path\n\n$source\n\n#end of listing"
    });
}

sub indent_text_in {
    my ($self, $source) = @_;
    $source =~ s/^/@{[ $self->indent ]}/mg;
    $source
}

has yada_start   => (
    is => 'ro',
    isa => 'Str',
    default => "# {{{ ExampleRunnerHide(?: ([^\n]+))?"
);

has yada_end => (
    is => 'ro',
    isa => 'Str',
    default => "# ExampleRunnerShow }}}"
);

# lines matching this will be collapsed into a single yada_pattern 
has yada_pattern => (
    is => 'ro',
    isa => 'Str',
    default => "# boring(?: ([^\n]+))?",
);

has yada_replace => (
    is => 'ro',
    isa => 'Str',
    default => "#...",
);
sub remove_yadas_from {
    my ($self, $source) = @_;

    # father, forgive me, for I have sinned,
    # it has been 8 months since my last code review,
    # i have been coding horrible things,  wicked things!
    # calling methods in a de-referenced array-ref, for interpolation sake.

    # single line yada
    $source =~ s/
        (?:
            ^
            (\s*)
            [^\n]*
            (?-x:@{[ $self->yada_pattern ]})
            $
        \n*)+/$1@{[ $self->yada_replace ]}$2\n/smgx;

    # a lengthy yada ...
    my $long_yada = qr{(?:\n)*@{[ $self->yada_start ]}(?s:.*?)@{[ $self->yada_end ]}(\n*)};
    # warn "\$long_yada = $long_yada";
    $source =~ s[$long_yada]{\n\n@{[ $self->yada_replace ]} $1\n\n}smg;

    chomp $source;
    $source 
}

1;

__END__
=pod

=head1 NAME

Pod::Elemental::Transformer::ExampleRunner - include/run examples scripts in your documentation without copy/paste

=head1 VERSION

version 0.002

=head1 SYNOPSIS

Tell C<ExampleRunner> what to run.
Insert C<=example> into your pod.

=head2 C<[-Transformer]> in your C<weaver.ini>:

 [-Transformer]
 transformer  = ExampleRunner
 command      =example

along with C<[PodWeaver]> in your C<dist.ini> if you're L<Dist::Zilla> inclined.

=head2 or C<use> it in a script 

  my $xform = Pod::Elemental::Transformer::ExampleRunner->new({qw[ command example script_path script/ ]});
  $xform->transform_node($pod_elemental_document);

see C< example/examplerunner-doc >

=head2 C<=example> commands in your pod 

You can include script source or output in your pod, with a pod command like:

 =example source showoff

for this dist, that would become something like:

#see ./example/showoff

  #! /usr/bin/perl -w
  #FOR: showing off the features of ExampleRunner
  #...use libraries 
  use MyApp::Example;
  
  my $app = MyApp::Example->new();
  use SomeLib qw[ frobulate ];
  
  #... read config files and do other stuff
  
  print frobulate(); 
  
  # an example of your module being used along with SomeLib
  for (@SomeLib::Plugins) { 
      print "Setting up plugin: $_\n";
      my $plugin_obj = SomeLib->factory( $_ );
      #...feed $plugin_obj
      $app->accept_frobulation( $_ => $plugin_obj->frobulate() );
  }
  $app->run(); # is now able to serve pre-frobulated results
  
  #... 

#end of listing

and if you wanted to run the script, and capture it's output, you'd use

 =example run showoff

which would look something like this:

#running ./example/showoff 

  behold the awesome power of SomeLib's frobulate implementation
  Setting up plugin: funky
  Oh my! MyApp::Example::accept_frobulation is happening!
  Setting up plugin: fresh
  Oh my! MyApp::Example::accept_frobulation is happening!
  Oh my! MyApp::Example::run is happening!

#.

=head1 KEEPING IT PUNCHY...

Often your example scripts will contain lots of boring setup code,
by C<yada>ing this code out your examples stay runnable,
and your docs stay focused on the features you're trying to explain...

If you want to just hide a couple of lines, use an inline-yada (consecutive lines lines matching C<yada_pattern>)...
For more lengthy chunks of boring stuff use a multi-line yadas (delimited with C<yada_{start,end}>)

=head2 ... with inline-C<yada>s

If a library wants you to pass in lots of options, and you need those options to make your example work, then keep them in your example script,
but tell C<ExampleRunner> that they're boring and it'll C<yada> them out.

 my $foo = ComplexLibrary->new({
    plugins => {
        often => {                                          # boring 
            scratchdir => '/tmp/',                          # boring 
            with       => [ qw[ --extra --support-large ]]  # boring 
        },                                                  # boring 
        sneaky => {                                         # boring 
            mask_user => 1,                                 # boring 
            show_full_name => 0,                            # boring 
        },                                                  # boring 
        options => {                                        # boring 
            no_laoder => 0                                  # boring 
        }                                                   # boring 
    }
 });
 # now we move on to code that's actually from my distribution... damn you ComplexLibrary!

and you'll get this in the pod:

 my $foo = ComplexLibrary->new({
    plugins => {
        #...
    }
 });
 # aah, that's a lot less cruft in my pod!

=head2 ... with a multi-line C<yada>s

Now, that's a lot of C<# boring> in your script too, so you might want a multi-line C<yada> instead, like this:

 my $foo = ComplexLibrary->new({
    plugins => {
        # {{{ ExampleRunnerHide ComplexLibrary requires lots of arguments!
        often => { 
            scratchdir => '/tmp/', 
            with       => [ qw[ --extra --support-large ]] 
        }, 
        sneaky => { 
            mask_user => 1, 
            show_full_name => 0, 
        }, 
        options => { 
            no_laoder => 0 
        } 
        # ExampleRunnerShow }}}
    }
 });
 # now we move on to code that's actually from my distribution... damn you ComplexLibrary!

you'll still get:

 my $foo = ComplexLibrary->new({
    plugins => {
        # ... ComplexLibrary requires lots of arguments!
    }
 });
 # now more of this example is to do with my code than with ComplexLibrary's setup

If your C<yada_start> or C<yada_pattern> captures something, it'll be tacked on after the C<yada> marker.

Multiple consecutive lines matching C<yada_pattern> will be collapsed down to one C<yada> using the B<last> C<< <stuff> >> captured

=head2 ... C<SYNOPSIS> example without C<yada>s 

Here is C<example/showoff> without the C<yada> blocks collapsed... 

#running ./example/cat example/showoff

  #! /usr/bin/perl -w
  #FOR: showing off the features of ExampleRunner
  use strict;             # boring
  use warnings;           # boring
  use lib 'somelib/lib';  # boring use libraries 
  use MyApp::Example;
  
  my $app = MyApp::Example->new();
  use SomeLib qw[ frobulate ];
  
  # {{{ ExampleRunnerHide read config files and do other stuff
  
  # the stuff in this block ( from yada_start to yada_end )
  # will be stripped out of the source listed in your POD
  # this way you can hide stuff that's not really that interesting
  # things like setting up stubs that let your example run without real libs
  #   (for example, SomeLib doesn't really export frobulate)
  
  sub frobulate {
          "behold the awesome power of SomeLib's frobulate implementation\n"
      }
  
  =pod 
  
  you can do things in your examples that would require lots of tedious
  configuration (say of a mysql server) that you really don't want to 
  force on your readers.
  
  They get to see the a couple of runs of your scripts without having to
  install everything, configure mysql and then find out your modules' not 
  as cool as they thought.
  
  And, you don't have to re-run the scripts and copy/paste their output
  every time you change them
  
  =cut 
  
  # ExampleRunnerShow }}}
  
  print frobulate(); 
  
  # an example of your module being used along with SomeLib
  for (@SomeLib::Plugins) { 
      print "Setting up plugin: $_\n";
      my $plugin_obj = SomeLib->factory( $_ );
      
      $plugin_obj->configure( SomeLib->configuration_for_plugin( $_ ) ); # boring
      $plugin_obj->init; # boring feed $plugin_obj
      $app->accept_frobulation( $_ => $plugin_obj->frobulate() );
  }
  $app->run(); # is now able to serve pre-frobulated results
  
  # {{{ ExampleRunnerHide
  # 
  #   This script is exclusive and non-transferrable property of yada yada 
  #   yada yada yada yada yada yada yada 
  #
  # ExampleRunnerShow }}}
  
  
  

#.

man, C<tl;dr>!

=head1 MORE EXAMPLES

you might want to check out the awesome scripts in the C<example/> directory for this dist:

#running ./example/list-examples 

  list-examples              lists the files in example/ (this script!)
  cat                        runs cat on files - meow!
  something-bad-happened     to demonstrate what happens when ExampleRunner runs something that dies and spews stuff to STDERR
  not-runnable               demonstrate what happens when a script can't be run
  examplerunner-doc          format the pod in ExampleRunner with ExampleRunner 
  somelib-examples           demonstrate ExampleRunner being used as more than one command on the same document
  showoff                    showing off the features of ExampleRunner

#.

which obviously came from this script:

#see ./example/list-examples

  :
  #FOR: lists the files in example/ (this script!)
  grep '#FOR:'  $( find example/ -type f ) | perl -ne 'next if /Binary file/;s{example/}{}; printf qq[%-25s %s], split /:#FOR:/'

#end of listing

C< /somelib > in this dist is a fake distribution with docs ...

=head1 CONFIGURATION 

These are the options you can set, and their defaults... you'd use these in your C<weaver.ini>:

 [-Transformer]
 transformer  = ExampleRunner
 script_path  = example/                                ; where I'll look for scripts to run/include
 command      = example                                 ; which pod command I'll expand
 indent       = '  '                                    ; the indent I'll add to source/output
 
 ; multi-line yada blocks
 yada_start   = # {{{ ExampleRunnerHide(?: ([^\n]+))?   ; start token, captures comment to be kept in pod
 yada_end     = # ExampleRunnerShow }}}                 ; end token 
 
 ; single-line yada blocks
 yada_pattern = # boring(?: ([^\n]+))?                  ; many lines matching these are considered a single yada
 
 ; all yadas are replaced with this, followed by the captures from above
 yada_replace = #...

=head1 DIAGNOSTICS 

If you find an empty block in place of your script's output, it could be one of...

=head2 permission denied

If you forget to make your scripts executable you'll get the message in the POD

# Couldn't run ./example/not-runnable: Permission denied

=head2 things going pear shaped in your script

If your perl script dies you'll likely just get an empty section where the script was (since STDERR is ignored), you see something similar happening in this script:

#see ./example/something-bad-happened

  :
  #FOR: to demonstrate what happens when ExampleRunner runs something that dies and spews stuff to STDERR
  echo "oh noes!" >&2;
  exit 1

#end of listing

#running ./example/something-bad-happened 

  

## something-bad-happened exited with 1

=head1 EXTENDING

If you find this library even remotely useful, you're likely to want it to do 
a little more than just running/inlining scripts... or maybe you'll want to disable something...

All the behaviours are in separate subs...

C<=example foo> is dispatched to C<< $self->_foo >>, and the rest of the command is passed on
so you can add new sub-commands by just adding a method to your subclass.
the thing C<_foo> returns is spliced back into the document.

You can re-use the yada support by calling C<< $self->remove_yadas_from($string) >>,
or remove it by replacing it with C< sub { return $_[1] } >.

=head1 FOLKS WHO HELPED OUT

Some of this is stolen from C<Pod::Elemental::Transformer::List>, but that doesn't mean C<rjbs> has anything to do with the horrible ideas behind this module.

both C<Apocalypse> and C<kentln> were helpful with the I<running ExampleRunner on ExampleRunner's docs during distribution> confusion I had ...

=head1 BUGS

Please report any bugs or feature requests to bug-pod-elemental-transformer-examplerunner@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Elemental-Transformer-ExampleRunner

=head1 AUTHOR

FOOLISH <FOOLISH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by FOOLISH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

