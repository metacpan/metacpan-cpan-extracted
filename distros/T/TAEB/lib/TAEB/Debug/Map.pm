package TAEB::Debug::Map;
use TAEB::OO;
use TAEB::Util qw/item_menu/;

sub msg_key {
    my $self = shift;
    my $key = shift;
    return unless $key eq ';';

    my ($x, $y) = (TAEB->x, TAEB->y);
    my $level = TAEB->current_level;
    my $z_index = 0;

    TAEB->redraw(botl => "Displaying $level");

    COMMAND: while (1) {
        my $tile = $level->at($x, $y);

        # draw some info about the tile at the top
        TAEB->display_topline($tile->debug_line);
        TAEB->place_cursor($x, $y);

        # where to next?
        my $c = TAEB->get_key;

           if ($c eq 'h') { --$x }
        elsif ($c eq 'j') { ++$y }
        elsif ($c eq 'k') { --$y }
        elsif ($c eq 'l') { ++$x }
        elsif ($c eq 'y') { --$x; --$y }
        elsif ($c eq 'u') { ++$x; --$y }
        elsif ($c eq 'b') { --$x; ++$y }
        elsif ($c eq 'n') { ++$x; ++$y }
        elsif ($c eq 'H') { $x -= 8 }
        elsif ($c eq 'J') { $y += 8 }
        elsif ($c eq 'K') { $y -= 8 }
        elsif ($c eq 'L') { $x += 8 }
        elsif ($c eq 'Y') { $x -= 8; $y -= 8 }
        elsif ($c eq 'U') { $x += 8; $y -= 8 }
        elsif ($c eq 'B') { $x -= 8; $y += 8 }
        elsif ($c eq 'N') { $x += 8; $y += 8 }
        elsif ($c eq ';' || $c eq '.' || $c eq "\e"
            || $c eq "\n" || $c eq ' ' || $c eq 'q' || $c eq 'Q') {
            last;
        }
        elsif ($c eq '<' || $c eq '>') {
            my $dz = $c eq '<' ? -1 : 1;

            # if we don't filter out these levels, then levels consisting of
            # just rock will make it through, because we initialize those
            # (apparently!)
            my @levels = grep { $_->turns_spent_on > 0 }
                         TAEB->dungeon->get_levels($level->z + $dz);
            next COMMAND if @levels == 0;

            $level = sub {
                # only one level, easy choice
                if (@levels == 1) {
                    return $levels[0];
                }

                # try to stay in the same branch
                for (@levels) {
                    return $_ if $_->branch eq $level->branch;
                }

                # or go to a level with an unknown branch
                for (@levels) {
                    return $_ if !$_->known_branch;
                }

                # finally, pick a level arbitrarily
                return $levels[0];
            }->();

            $z_index = 0;

            TAEB->redraw(level => $level, botl => "Displaying $level");

            if (@levels > 1) {
                TAEB->display_topline("Note: there are " . @levels . " levels at this depth. Use v to see the next.");
            }
        }
        elsif ($c eq 'v') {
            my @levels = grep { $_->turns_spent_on > 0 }
                         TAEB->dungeon->get_levels($level->z);
            next COMMAND if @levels < 2;

            $level = $levels[++$z_index % @levels];
            TAEB->redraw(level => $level, botl => "Displaying $level");
        }
        elsif ($c eq 'i') {
            my @items = $level->at($x, $y)->items;
            my $description = "The items on $tile";

            if (@items == 0) {
                $description = "The items on $level";
                @items = $level->items;
            }

            item_menu($description, \@items);
        }
        elsif ($c eq 't') {
            item_menu("Tile data for ($x, $y)", $tile);
        }
        elsif ($c eq 'T') {
            item_menu("Level data for $z_index", $level);
        }
        elsif ($c eq 'm') {
            if (my $monster = $tile->monster) {
                item_menu("Monster data for $monster", $monster);
            }
        }

        $x %= 80;
        $y = ($y-1)%21+1;
    }

    # back to normal
    TAEB->redraw;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;
