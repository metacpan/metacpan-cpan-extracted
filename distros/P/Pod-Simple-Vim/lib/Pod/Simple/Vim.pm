package Pod::Simple::Vim;

use strict;
use warnings;

use Text::Wrap;

our $VERSION = '0.02';

use base 'Pod::Simple::Methody';

my $list_indent_level = 0;
my $text_indent_level = 0;
my $initial_tab;
my $text_bin;
my $wrap = 0;
my $wrap_text_item = 0;
my $first_item;


#---------------------------------------------------------------------------
#  HANDLE VARIOUS TYPES OF TEXT
#---------------------------------------------------------------------------

#GENERAL TEXT HANDLER
sub handle_text 
{
	my($self, $text) = @_;
	if ($wrap)
	{
		$text_bin .= $text;
	} else {
		print OUTFH $text;
	}
}

#ORDINARY TEXT
sub start_Para
{
	$wrap = 1;
	print OUTFH "\n" unless $first_item;
	undef $first_item;
}

sub end_Para
{
	$wrap = 0;
	$initial_tab = "\040\040\040\040"x$list_indent_level if $list_indent_level;
	local $Text::Wrap::unexpand = 0;
	#local $Text::Wrap::columns = 78;
	print OUTFH wrap($initial_tab, $initial_tab, $text_bin);
	print OUTFH "\n";
	undef $text_bin;
}

#VERBATIM
sub start_Verbatim
{
	my($self, $attrs) = @_;
	print OUTFH ">\n";
	$wrap = 1;
}

sub end_Verbatim
{
	my ($self, $attrs) = @_;
	$initial_tab = "";
	$initial_tab = "\040\040\040\040"x$list_indent_level if $list_indent_level;
	my @lines = split /\n/, $text_bin;
	print OUTFH $initial_tab, $_, "\n" for @lines;
	undef $wrap;
	undef $text_bin;
	print OUTFH "<";
}

#---------------------------------------------------------------------------
#  HANDLE HEADINGS
#---------------------------------------------------------------------------

#HEAD1
sub start_head1 {
	my($self, $attrs) = @_;
	print OUTFH "\n" unless $first_item;
	undef $first_item;
}

sub end_head1 {
	my($self) = @_;
	print OUTFH " ~\n";
}

#HEAD2
sub start_head2 {
	my($self, $attrs) = @_;
	print OUTFH "\n" unless $first_item;
	undef $first_item;
}

sub end_head2 {
	my($self) = @_;
	print OUTFH " ~\n";
}

#HEAD3
sub start_head3 {
	my($self, $attrs) = @_;
	print OUTFH "\n" unless $first_item;
	print OUTFH " ";
	undef $first_item;
}

sub end_head3 {
	my($self) = @_;
	print OUTFH " ~\n";
}

#HEAD4
sub start_head4 {
	my($self, $attrs) = @_;
	print OUTFH "\n" unless $first_item;
	print OUTFH "  ";
	undef $first_item;
}

sub end_head4 {
	my($self) = @_;
	print OUTFH " ~\n";
}

#---------------------------------------------------------------------------
# HANDLE LISTS  
#---------------------------------------------------------------------------

#TEXT
sub start_over_text {
	my($self, $attrs) = @_;
	$list_indent_level++;
}

sub end_over_text {
	my($self) = @_;
	$list_indent_level--;
}

sub start_item_text {
	my($self, $attrs) = @_;
	print OUTFH "\n" unless $first_item;
	undef $first_item;
	print OUTFH "\t"x$list_indent_level;
}

sub end_item_text {
	my($self) = @_;
	print OUTFH "\n";
}

#BULLET
sub start_over_bullet {
	my($self, $attrs) = @_;
	$list_indent_level++;
}

sub end_over_bullet {
	my($self) = @_;
	$list_indent_level--;
}

sub start_item_bullet {
	my($self, $attrs) = @_;
	print OUTFH "\n" unless $first_item;
	undef $first_item;
	print OUTFH "\t"x($list_indent_level-1) if $list_indent_level;
	print OUTFH "  * ";
	#$in_bullet++;
	$wrap = 1;
}

sub end_item_bullet {
	my($self) = @_;
	$initial_tab = "\040\040\040\040"x$list_indent_level if $list_indent_level;
	local $Text::Wrap::unexpand = 0;
	print OUTFH wrap("", $initial_tab, $text_bin);
	print OUTFH "\n";
	undef $text_bin;
	undef $wrap;
}

#NUMBER
sub start_over_number {
	my($self, $attrs) = @_;
	$list_indent_level++;
}

sub end_over_number {
	my($self) = @_;
	$list_indent_level--;
}

sub start_item_number {
	my($self, $attrs) = @_;
	print OUTFH "\n" unless $first_item;
	undef $first_item;
	print OUTFH "\t"x($list_indent_level-1) if $list_indent_level;
	print OUTFH " " . $attrs->{'number'} . ". ";
	#$in_bullet++;
	$wrap = 1;
}

sub end_item_number {
	my($self) = @_;
	$initial_tab = "\040\040\040\040"x$list_indent_level if $list_indent_level;
	local $Text::Wrap::unexpand = 0;
	print OUTFH wrap("", $initial_tab, $text_bin);
	print OUTFH "\n";
	undef $text_bin;
	undef $wrap;
}

#---------------------------------------------------------------------------
#  VIM MODELINE
#---------------------------------------------------------------------------

sub start_Document
{
	my $self = shift;
	$first_item = 1;
	*OUTFH = $self->output_fh();
}

sub end_Document
{
    print OUTFH "\n\nvim:nonu:ts=4:syn=perldoc:noet:lbr:bt=nofile:noma:bh=delete:noswf";
}

1;

__END__

=head1 NAME

Pod::Simple::Vim - Render pod for display in vim

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  # See Pod::Simple's documentation for interface details
  use Pod::Simple::Vim;
  
  my $parser = Pod::Simple::Vim->new;
  
  my $perldoc;
  $parser->output_string(\$perldoc);
  $parser->parse_file($pod_filename); 
  
  print $perldoc;

=head1 DESCRIPTION

This module translates pod into a format used by the vim PERLDOC2 plugin to display perl documentation with syntax highlighting, rather than as plain text. 

=head1 USAGE

This module is not meant to be used directly, it is a backend to the vim PERLDOC2 plugin. 

=head1 AUTHOR

Petar Shangov, C<< <pshangov at yahoo.com> >>

=head1 SEE ALSO

L<Pod::Simple>, the PERLDOC2 plugin at L<http://www.vim.org/scripts/script.php?script_id=2171> 

=head1 BUGS

Please report any bugs or feature requests pertaining to either this module or the PERLDOC2 plugin to C<bug-pod-simple-vim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Simple-Vim>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Petar Shangov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
