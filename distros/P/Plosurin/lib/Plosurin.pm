#===============================================================================
#
#  DESCRIPTION: Plosurin - Perl 5 implementation of Closure Templates
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Plosurin;

=head1 NAME

Plosurin - Perl 5 implementation of Closure Templates

=head1 SYNOPSIS

For template C<example.soy> with content:

    {namespace mytest}
    
    /**
      * Simple test
     */
    {template .Hello}
    <h1>Foreach example</h1>
    {foreach $a in [1,2]}
        <p>Line: {$a}</p><br/>
    {/foreach}
    <p>Ok</p>
    {/template}

To get Perl 5 module (MyApp, for example), just run the following command:

        plosurin.p5 -package MyApp < example.soy > MyApp.pm

Use template in your Perl 5 program:

        use MyApp;
        print &MyApp::mytest_Hello();

or get help:

         perldoc MyApp.pm

=head1 DESCRIPTION

Plosurin - Perl implementation of Closure Templates. 

=head2 Template Structure

Every Soy file should have these components, in this order:

=over

=item * A namespace declaration.

=item * One or more template definitions.

=back

Here is an example template: 

  {namespace examples.simple}
  /**
   * Says hello to a person.
   * @param name The name of the person to say hello to.
   */
  {template .helloName}
    Hello {$name}!
  {/template}


=head2 Command Syntax

Commands are instructions that you give the template compiler to create templates and add custom logic to templates. Put commands within Closure Template tags, which are delimited by braces (C<{}>).

The first token within a tag is the command name (the print command is implied if no command is specified), and the rest of the text within the tag (if any) is referred to as the command text. Within the template you can enclose other commands to evaluate conditional expressions, iterate over data objects, or print messages.

 {/foreach}
 {if length($items) > 5}
 {msg desc="Says hello to the user."}

If a command has a corresponding end command, then the end command's name is a C</> followed by the name of the start command, e.g. foreach and C</foreach>. 

=cut

package Plo::File;
use Plosurin::SoyTree;
use base 'Soy::base';

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );

    #set namespace
    my $namespace = $self->{namespace}->{id};

    #set src file
    my $file = $self->{file};
    foreach my $tmpl ( @{ $self->{templates} } ) {
        $tmpl->{namespace} = $namespace;
        $tmpl->{srcfile}   = $file;
    }

    $self;
}

sub namespace {
    $_[0]->{namespace}->{id};
}

sub childs {
    my $self = shift;
    return [ $self->templates ];
}

=head2 templates

Return array of tempaltes

=cut

sub templates {
    my $self = shift;
    @{ $self->{templates} };
}

package Plo::template;
use strict;
use warnings;
use Plosurin::SoyTree;
use base 'Soy::base';

sub new {
    my $class = shift;
    bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}

sub body { $_[0]->{template_block}->{raw_template} }
sub name { $_[0]->{template_block}->{start_template}->{name} }

sub comment {
    return join "\n", map { $_->{raw_str} } @{ $_[0]->{header}->{h_comment} };
}
sub params { exists $_[0]->{header}->{h_params} ? @{ $_[0]->{header}->{h_params} } : ()}
sub full_name { my $self = shift; $self->{namespace} . $self->name }

sub namespace {
    $_[0]->{namespace}->{id};
}

#parse body and return Soy tree
sub childs {
    my $self = shift;
    my $plo  = new Plosurin::SoyTree(
        src     => $self->body,
        offset  => $self->{template_block}->{matchline},
        srcfile => $self->{srcfile}
    );
    die $plo unless ref $plo;

    my $reduced = $plo->reduced_tree;
    return $reduced;
}

1;

package Plo::h_params;

sub new  {
    my $class = shift;
    bless ( ($#_ == 0) ? shift : {@_}, ref($class) || $class);
}

sub name { $_[0]->{id} }
sub is_notreq {$_[0]->{is_notreq} }
sub comment {$_[0]->{raw_str}}

1;

package Plosurin;

=head1 Perl 5 code generator API

    use Plosurin;
    my $p = new Plosurin::;
    my $in_fd = new IO::File:: "< $infile" or die "$infile: $!";
    my $nodes = $p->parse( $in, "file_name.soy");
    say $p->as_perl5( { package => "MyApp::Templates" }, $nodes );


=cut

use strict;
use warnings;
use v5.10;
our $VERSION = '0.1.2';
use Regexp::Grammars;
use Plosurin::Grammar;
use Plosurin::Context;
use Plosurin::SoyTree;
use Plosurin::To::Perl5;
use Plosurin::Writer::Perl5;
our $file = "???";

sub new {
    my $class = shift;
    bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}

sub parse {
    my $self = shift;
    my $ref  = shift;
    our $file = shift;
    my $r = qr{
       <extends: Plosurin::Template::Grammar>
        <matchline>
        \A <File> \Z
    }xms;
    if ( $ref =~ $r ) {
        return {%/}->{File};
    }
    undef;
}

=head2 as_perl5 { package=>"MyApp::Tmpl" }, $node1[, $noden]

Export nodes as perl5 package 

=cut

use Data::Dumper;

sub as_perl5 {
    my $self = shift;
    my $opt  = shift;
    return " need at least one $file" unless scalar(@_);
    my @files = map { ( ref($_) eq 'ARRAY' ) ? @{$_} : ($_) } @_;
    my @alltemplates = ();

    my $package = $opt->{package} || die "
      use as_perl5( { package => ... } ) !";

    my $ctx = new Plosurin::Context(@files);

    #    print Dumper (\@files);
    my $p5 = new Plosurin::To::Perl5(
        'context' => $ctx,
        'writer'  => new Plosurin::Writer::Perl5,
        'package' => $package,
    );
    $p5->start_write();
    $p5->write(@files);
    $p5->end_write();
    my $res = $p5->wr->{code};
    wantarray() ? ( $res, @{ $p5->{tmpls} } ) : $res;
}

1;
__END__

=head1 SEE ALSO

Closure Templates Documentation L<http://code.google.com/closure/templates/docs/overview.html>

Perl 6 implementation L<https://github.com/zag/plosurin>


=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

