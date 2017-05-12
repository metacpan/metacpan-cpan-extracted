
sub load_test_data {
    (
        # title, input text, filtered text
        [ "bold text", "\e[1mbold text", "<ESC>[1mbold text" ],
        [ "term title", "\e]0;OH HAI\a",  "<ESC>]0;OH HAI<BEL>" ],
        [
          "clear screen, cursor position, red blinking text",
          "\a\e[2J\e[2;5m\e[1;31mI CAN HAS UR PWNY\n\e[2;25m\e[22;30m\e[3q",
          "<BEL><ESC>[2J<ESC>[2;5m<ESC>[1;31mI CAN HAS UR PWNY<LF><ESC>[2;25m<ESC>[22;30m<ESC>[3q"
        ],
    )
}

1
