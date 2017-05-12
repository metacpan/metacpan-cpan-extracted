# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package PPIx::PerlCompiler::Statement;

use strict;
use warnings;

BEGIN {
    require PPI::Statement;

    push @PPI::Statement::ISA, __PACKAGE__;
}

sub contains_strict_pattern {
    my ( $self, @items ) = @_;

    return 0 unless @items;
    return 0 unless @{ $self->{'children'} };

    my $found     = 0;
    my $expected  = scalar @items;
    my @remaining = @items;

    foreach my $child ( @{ $self->{'children'} } ) {
        last unless @remaining;

        next if $child->isa('PPI::Token::Whitespace');
        next if $child->isa('PPI::Token::Comment');

        my $current = $remaining[0];

        if ($found) {
            return 0 unless $child->matches( @{$current} );
        }
        else {
            next unless $child->matches( @{$current} );
        }

        $found++;
        shift @remaining;
    }

    return $found == $expected;
}

sub contains_loose_pattern {
    my ( $self, @items ) = @_;

    my $found_matches = 0;

    my $item_i  = 0;
    my $child_i = 0;

    while (1) {
        return 0 if $item_i > $#items && $child_i > $#{ $self->{'children'} };

        my $item       = $items[$item_i];
        my $child_node = $self->child($child_i);

        last unless $item;
        last unless $child_node;

        my ( $type, $expected ) = @{$item};

        if ( $child_node->matches( $type, $expected ) ) {
            $found_matches++;
            $item_i++;
        }

        $child_i++;
    }

    return scalar(@items) == $found_matches;
}

sub isa_local_assignment {
    my ($self) = @_;

    my $child = $self->non_whitespace_child(0) or return 0;

    return $child->matches( 'PPI::Token::Word' => 'local' );
}

sub isa_nonlexical_assignment_to {
    my ( $self, $var ) = @_;

    return 0 if $self->isa_local_assignment;

    return $self->contains_loose_pattern(
        [ 'PPI::Token::Symbol'   => $var ],
        [ 'PPI::Token::Operator' => qr{^(?:\Q||\E|&&|//|<<|>>|\Q**\E|[-+*/%.|&^x])?=$} ]
    );
}

sub contains_call_to {
    my ( $self, $call ) = @_;

    my $first = $self->non_whitespace_child(0) or return 0;

    return 0
      if $first && $first->matches( 'PPI::Token::Word' => 'sub' );

    if ( $self->isa('PPI::Statement::Expression') ) {
        return 0
          if $self->contains_strict_pattern(
            [ 'PPI::Token::Word'     => $call ],
            [ 'PPI::Token::Operator' => qr/^(?:=>|,)$/ ]
          );
    }

    foreach my $child ( @{ $self->{'children'} } ) {
        return 1 if $child->matches( 'PPI::Token::Word' => $call );
    }

    return 0;
}

sub concise_string {
    my ($self) = @_;

    my $string = $self->content;

    chomp $string;

    $string =~ s/\s+/ /g;

    return $string;
}

sub mutates_special_var {
    my ($self) = @_;

    my $pattern = qr{^
        (?:
            \$[\(\)<>"\/0] |
            [\$\@%](?:
                  ENV
                | SIG
                | ARGV
                | ARGVOUT
                | REAL_GROUP_ID
                | GID
                | REAL_USER_ID
                | UID
                | EFFECTIVE_GROUP_ID
            )
        )
    $}xms;

    return $self->isa_nonlexical_assignment_to($pattern);
}

sub performs_system_io {
    my ($self) = @_;

    my @patterns;

    #
    # Core Perl I/O builtins and POSIX:: variants
    #
    push @patterns, qr{^
        (?:sys|POSIX::|)(?:
              open(?:dir|)
            | close(?:dir|)
            | (?:f|)read
            | (?:f|)write
            | print(?:f|)
            | unlink
            | rmdir
            | tell
            | dup(?:|2)
            | pipe
            | chmod
            | chown
            | creat
            | mknod
            | mkdir
            | exec(?:ve|le|l|v|lp|vp|)
            | fcntl
            | fdopen
            | feof
            | eof
            | (?:f|)flush
            | (?:f|)seek
        )
    $}xms;

    #
    # IPC::Open3
    #
    push @patterns, qr{^(?:IPC::Open3::|)open3$};

    foreach my $pattern (@patterns) {
        return 1 if $self->contains_call_to($pattern);
    }

    return 0;
}

sub performs_process_ops {
    my ($self) = @_;

    my $pattern = qr{^
        (?:POSIX::|)(?:
            | exec(?:ve|le|l|v|lp)
            | exit
            | fork
        )
    $}xms;

    return $self->contains_call_to($pattern);
}

sub has_string_eval {
    my ($self) = @_;

    my $last;

    foreach my $child ( @{ $self->{'children'} } ) {
        next if $child->isa('PPI::Token::Whitespace');

        if ( $last && $last->matches( 'PPI::Token::Word' => 'eval' ) ) {
            return 1 if $child->isa('PPI::Token::Quote');

            if ( $child->isa('PPI::Structure::List') ) {
                my $first = $child->item(0) or return 0;

                return 1 if $first->isa('PPI::Token::Quote');
            }
        }

        $last = $child;
    }

    return 0;
}

1;
