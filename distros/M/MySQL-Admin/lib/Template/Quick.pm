package Template::Quick;
use strict;
use utf8;
use warnings;
use MySQL::Admin qw(init translate);
require Exporter;
use vars qw($defaultconfig $tmp $DefaultClass @EXPORT_OK @ISA $sStyle $bModPerl);
@ISA                          = qw(Exporter);
@Template::Quick::EXPORT      = qw(initTemplate appendHash Template initArray);
%Template::Quick::EXPORT_TAGS = ( 'all' => [qw(initTemplate appendHash Template initArray  )] );
$Template::Quick::VERSION     = '1.18';
$DefaultClass                 = 'Template::Quick' unless defined $Template::Quick::DefaultClass;
our %tmplate;
$sStyle        = 'mysql';
$bModPerl      = ( $ENV{MOD_PERL} ) ? 1 : 0;
$defaultconfig = '%CONFIG%';

=head1 NAME

Template::Quick  - A simple Template System

=head1 SYNOPSIS

        use Template::Quick;

        $temp = new Template::Quick( {path => "./", template => "template.html"});

        @data = (

{name => 'Header'},

{name => 'link', text => "Website", href => "http://lindnerei.de"},

{name => 'link', text => "Cpan", href => "http://search.cpan.org~lze"},

{name => 'Footer'}

        );

        print $temp->initArray(\@data);

        template.html:

        [Header]

        A simple text.<br/>

        [/Header]

        [link]

        <a href="[href/]">[text/]</a>

        [/link]

        [Footer]

        <br/>example by [tr=firstname/] Dirk  [tr=name/] Lindner

        [/Footer]


=head2 new

see SYNOPSIS

=cut

sub new {
    my ( $class, @initializer ) = @_;
    my $self = {};
    bless $self, ref $class || $class || $DefaultClass;
    $self->initTemplate(@initializer) if (@initializer);
    return $self;
} ## end sub new

=head2 initTemplate

       %template = (

                path     => "path",

                style    => "style", #defualt is lze

                template => "index.html",

       );

       initTemplate(\%template);

=cut

sub initTemplate {
    my ( $self, @p ) = getSelf(@_);
    my $hash = $p[0];
    $DefaultClass = $self;
    my $configfile = defined $hash->{config} ? $hash->{config} : $defaultconfig;
    init($configfile) unless $bModPerl;
    use Fcntl qw(:flock);
    use Symbol;
    my $fh = gensym;
    $sStyle = $hash->{style} if defined $hash->{style};
    my $m_sFile = "$hash->{path}/$sStyle/$hash->{template}";
    open $fh, "$m_sFile" or warn "$!: $m_sFile";
    seek $fh, 0, 0;
    my @lines = <$fh>;
    close $fh;
    my ( $text, $o );

    for (@lines) {
        $text .= chomp $_;
      SWITCH: {
            if ( $_ =~ /\[([^\/|\]|']+)\]([^\[\/\1\]]*)/ ) {
                $tmplate{$1} = $2;
                $o = $1;
                last SWITCH;
            } ## end if ( $_ =~ /\[([^\/|\]|']+)\]([^\[\/\1\]]*)/[([)])
            if ( defined $o ) {
                if ( $_ =~ /[^\[\/$o\]]/ ) {
                    $tmplate{$o} .= $_;
                    last SWITCH;
                } ## end if ( $_ =~ /[^\[\/$o\]]/)
            } ## end if ( defined $o )
        } ## end SWITCH:
    } ## end for (@lines)
    $self->initArray( $p[1] ) if ( defined $p[1] );
} ## end sub initTemplate

=head2 Template()

see initTemplate

=cut

sub Template {
    my ( $self, @p ) = getSelf(@_);
    return $self->initArray(@p);
} ## end sub Template

=head2 appendHash()

appendHash(\%hash);

=cut

sub appendHash {
    my ( $self, @p ) = getSelf(@_);
    my $hash = $p[0];
    my $text = $tmplate{ $hash->{name} };
    foreach my $key ( keys %{$hash} ) {
        if ( defined $text && defined $hash->{$key} ) {
            if ( defined $key && defined $hash->{$key} ) {
                $text =~ s/\[($key)\/\]/$hash->{$key}/g;
                $text =~ s/\[tr=(\w*)\/\]/translate($1)/eg;
            } ## end if ( defined $key && defined...)
        } ## end if ( defined $text && ...)
    } ## end foreach my $key ( keys %{$hash...})
    return $text;
} ## end sub appendHash

=head2 initArray()

=cut

sub initArray {
    my ( $self, @p ) = getSelf(@_);
    my $tree = $p[0];
    $tmp = undef if ( defined $tmp );
    for ( my $i = 0 ; $i < @$tree ; $i++ ) {
        $tmp .= $self->appendHash( \%{ @$tree[$i] } );
    } ## end for ( my $i = 0 ; $i < ...)
    return $tmp;
} ## end sub initArray

=head2 getSelf()

=cut

sub getSelf {
    return @_ if defined( $_[0] ) && ( !ref( $_[0] ) ) && ( $_[0] eq 'Template::Quick' );
    return ( defined( $_[0] ) && ( ref( $_[0] ) eq 'Template::Quick' || UNIVERSAL::isa( $_[0], 'Template::Quick' ) ) )
      ? @_
      : ( $Template::Quick::DefaultClass->new, @_ );
} ## end sub getSelf

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 LICENSE

Copyright (C) 2008 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut
1;
