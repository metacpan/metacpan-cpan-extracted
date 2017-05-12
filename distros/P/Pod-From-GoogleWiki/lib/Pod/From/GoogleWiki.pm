package Pod::From::GoogleWiki;

use warnings;
use strict;
use vars qw/$VERSION/;
$VERSION = '0.07';

use Text::SimpleTable;

sub new {
	my $class = shift;
	my $self = { @_ };
	
	unless ( exists $self->{tags} ) {
	    $self->{tags} = {
            strong		=> sub { "B<$_[0]>" },
        	italic      => sub { "I<$_[0]>" },
        	strike   	=> sub { "C<--$_[0]-->" },
        	superscript => sub { "($_[0])" },
        	subscript   => sub { "($_[0])" },
        	inline      => sub { "C<$_[0]>" },
        	inline_code => sub { "C<<<$_[0]>>>" },
        	strong_tag  => qr/\*(.+?)\*/,
        	italic_tag  => qr/_(.+?)_/,
        	strike_tag  => qr/\~\~(.+?)\~\~/,
        	superscript_tag => qr/\^(.+?)\^/,
        	subscript_tag   => qr/\,\,(.+?)\,\,/,
        	inline_tag  => qr/\`(.+?)\`/,
            inline_code_tag => qr/\{\{\{(.+?)\}\}\}/,

            link		=> sub {
                my $link = shift;
                return $link if ($link =~ /\]$/); # for [text link], deal later
                ($link, my $title)    = split(/\s+/, $link, 2);
                my $output;
                # it's an image
                if ($link =~ /\.(jpe?g|png|bmp|gif)$/is
                    or ($title and $title =~ /\.(jpe?g|png|bmp|gif)$/is) ) {
                    $output = "=begin html\n\n";
                    if ($title) {
                        $output .= "<a href='$link'><img src='$title' /></a>\n\n";
                    } else {
                        $output .= "<img src='$link' />\n\n";
                    }
                    $output .= "=end html\n";
                } else {
                    if ($title) {
                        # for [http://search.cpan.org/perldoc?Pod::From::GoogleWiki Pod::From::GoogleWiki]
                        if ($link eq "http://search.cpan.org/perldoc?$title") {
                            $output = "L<$title>";
                        } else {
                            $output = "L<$link|$title>";
                        }
                    } else {
                        $output = "L<$link>";
                    }
                }
                return $output;
            },
            
            schemas => [ qw( http https ftp mailto gopher ) ],
        };
    }

	return bless $self => $class;
}

sub wiki2pod {
    my ($self, $text) = @_;
    
    # rest block_mark
    $self->{_block_mark} = {};
    
    my $tags = $self->{tags};
    
    my $output = ''; my $do_last_line = 1;
    my @lines = split(/\r?\n/, $text);
    foreach my $line_no ( 0 .. $#lines ) {
        my $line = $lines[$line_no];
        my $pre_line = ($line_no > 0) ? $lines[ $line_no - 1 ] : '';
        
        # skip some lines
        next if (not $output and $line =~ /^\#/); # like #labels

        # 1, code
        if ( $line =~ /^\}\}\}$/ ) {
            $self->{_block_mark}->{is_code} = 0;
            $do_last_line = 0;
            $output .= "\n" unless ($output =~ /\n{2,}$/);
            next;
        } elsif ( $line =~ /^\{\{\{$/) {
            $self->{_block_mark}->{is_code} = 1;
            $output .= "\n" unless ($output =~ /\n{2,}$/);
            next;
        } elsif ( $self->{_block_mark}->{is_code} ) {
            $output .= "  $line\n" and next;
        }
        
        # 2, table
        if ( $line =~ /^\|\|(.*?)\|\|$/) {
            if ( $self->{_block_mark}->{in_table} ) {
                push @{ $self->{_block_mark}->{trs} }, $self->format_line($line);
            } else {
                $self->{_block_mark}->{in_table} = 1;
                $self->{_block_mark}->{trs} = [ $self->format_line($line) ];
            }
            if ($line_no == $#lines) { # if that's last line
                $self->{_block_mark}->{in_table} = 0;
                my @trs = @{ $self->{_block_mark}->{trs} };            
                $output .= $self->make_table( @trs ) and next;
            } else {
                next;
            }
        } elsif ( $self->{_block_mark}->{in_table} ) {
            $self->{_block_mark}->{in_table} = 0;
            my @trs = @{ $self->{_block_mark}->{trs} };            
            $output .= $self->make_table( @trs ) and next;
        }
        
        if ($line =~ /^\s*$/) { # blank line
            $do_last_line = 1;
            $self->{_block_mark}->{in_list} = 0;
            $output .= "\n" and next;
        }
        
        # 2, header
        if ($line =~ /^(=+)\s+(.*?)\s+\1\s*$/) {
            my $h_level = length($1);
            my $text    = $self->format_line($2);
            $do_last_line = 0;
            $output .= "\n" unless ($output =~ /\n{2,}$/);
            $output .= "=head$h_level $text\n" and next;
        }
        
        # 3, list into code needs a newline in front
        if ($line =~ /^\s+[\*|\#]/) {
            unless ( $self->{_block_mark}->{in_list} ) {
                if ($output !~ /\n{2,}$/) {
                    $output .= "\n";
                }
            }
            $self->{_block_mark}->{in_list} = 1;
        }
        if ($line !~ /^\s+/) {
            if ($self->{_block_mark}->{in_list} and $output !~ /\n{2,}$/) {
                $output .= "\n";
            }
            $self->{_block_mark}->{in_list} = 0;
        }
        
        # at last
        $output .= $self->format_line($line) . "\n";
        $do_last_line = 1;
    }

    if ($do_last_line) {
        my $last_line = 0;
        while ($text =~ s/\n$//isg) {
            $last_line++;
        }
        $output =~ s/\n$//isg;
        $output .= "\n" x $last_line;
    }
    
    # if list into code, last we need a newline after
    if ($self->{_block_mark}->{in_list} and $output !~ /\n{2,}$/) {
        $output .= "\n";
    }
    
    return $output;
}

sub format_line {
    my ($self, $line) = @_;
    
    my $tags = $self->{tags};
    
    foreach my $type (qw/strong italic strike superscript subscript inline inline_code/) {
        my $sym     = $tags->{"${type}_tag"};
        my $pod_sym = $tags->{$type};
        $line =~ s/$sym/$pod_sym->($1)/eg;
    }
    
    # deal with link
    my $schemas = join('|', @{$tags->{schemas}});
    $line =~ s!(^|\s+)(($schemas):\S+)!$1 . $tags->{link}->($2)!egi;
    
    while (my @pieces = $self->find_innermost_balanced_pair( $line, '[', ']' ) ) {
		my ($tag, $before, $after) = map { defined $_ ? $_ : '' } @pieces;
		my $extended               = $tags->{link}->( $tag ) || '';
		$line                      = $before . $extended . $after;
	};
    
    return $line;
}

sub make_table {
    my ($self, @trs) = @_;

    @trs = map { $_ =~ s/^\|\|(.*?)\|\|$/$1/isg; $_ } @trs;
    
    my $first_line = shift @trs;
    my @cols = split(/\s*\|\|\s*/, $first_line);
    @cols = map { [ length($_), $_ ] } @cols;

    my $t = Text::SimpleTable->new(@cols);
    foreach my $tr (@trs) {
        $t->row( split(/\s*\|\|\s*/, $tr) );
    }
    return $t->draw;
}

sub find_innermost_balanced_pair {
	my ($self, $text, $open, $close) = @_;

	my $start_pos             = rindex( $text, $open              );
	return if $start_pos == -1;

	my $end_pos               =  index( $text, $close, $start_pos );
	return if $end_pos   == -1;

	my $open_length           = length( $open );
	my $close_length          = length( $close );
	my $close_pos             = $end_pos + $close_length;
	my $enclosed_length       = $close_pos - $start_pos;

	my $enclosed_atom        = substr( $text, $start_pos, $enclosed_length );
	return substr( $enclosed_atom, $open_length, 0 - $close_length ),
	       substr( $text, 0, $start_pos ),
		   substr( $text, $close_pos );
}

1;
__END__

=head1 NAME

Pod::From::GoogleWiki - convert from Google Code wiki markup to POD

=head1 SYNOPSIS

    use Pod::From::GoogleWiki;

    my $pfg = Pod::From::GoogleWiki->new();
    my $wiki = read_from_file('wiki/Help.wiki');
    my $pod  = $pfg->wiki2pod($wiki);

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

Thanks to schwern: L<http://use.perl.org/~schwern/journal/37476>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
