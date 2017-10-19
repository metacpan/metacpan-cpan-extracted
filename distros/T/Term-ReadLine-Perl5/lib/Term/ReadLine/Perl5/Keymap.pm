package Term::ReadLine::Perl5::Keymap;
use strict; use warnings;
=head1 NAME

Term::ReadLine::Perl5::Keymap

=head1 DESCRIPTION

A non-OO package subsidiary to L<Term::ReadLine::Perl5::readline> to
initialize keymaps.

=cut

=head1 SUBROUTINES

=head2 KeymapEmacs

GNU Emacs key bindings

=cut

use Exporter;
use vars qw(@ISA @EXPORT); @ISA = qw(Exporter);
@EXPORT = qw(KeymapEmacs KeymapVi KeymapVicmd KeymapVipos KeymapVisearch);

sub KeymapEmacs($$$) {
    my ($fn, $keymap, $inDOS) = @_;
    &$fn($keymap, 'SelfInsert', 'emacs_keymap',
	($inDOS ? () : ('C-@',  'SetMark') ),
	'C-a',  'BeginningOfLine',
	'C-b',  'BackwardChar',
	'C-c',  'Interrupt',
	'C-d',  'DeleteChar',
	'C-e',  'EndOfLine',
	'C-f',  'ForwardChar',
	'C-g',  'Abort',
	'M-C-g', 'Abort',
	'C-h',  'BackwardDeleteChar',
	"TAB" , 'Complete',
	"C-j" , 'AcceptLine',
	'C-k',  'KillLine',
	'C-l',  'ClearScreen',
	"C-m" , 'AcceptLine',
	'C-n',  'NextHistory',
	'C-o',  'OperateAndGetNext',
	'C-p',  'PreviousHistory',
	'C-q',  'QuotedInsert',
	'C-r',  'ReverseSearchHistory',
	'C-s',  'ForwardSearchHistory',
	'C-t',  'TransposeChars',
	'C-u',  'UnixLineDiscard',
	##'C-v', 'QuotedInsert',
	'C-v',  'HistorySearchForward',
	'C-w',  'UnixWordRubout',
	qq/"\cX\cX"/,   'ExchangePointAndMark',
	qq/"\cX\cR"/,   'ReReadInitFile',
	qq/"\cX?"/,     'PossibleCompletions',
	qq/"\cX*"/,     'InsertPossibleCompletions',
	qq/"\cX\cU"/,   'Undo',
	qq/"\cXu"/,     'Undo',
	qq/"\cX\cW"/,   'KillRegion',
	qq/"\cXw"/,     'CopyRegionAsKill',
	qq/"\cX\ec\\*"/,        'DoControlVersion',
	qq/"\cX\ec\0"/, 'SetMark',
	qq/"\cX\ec\@"/, 'SetMark',
	qq/"\cX\ec "/,  'SetMark',
	qq/"\cX\em\\*"/,        'DoMetaVersion',
	qq/"\cX\@c\\*"/,        'DoControlVersion',
	qq/"\cX\@c\0"/, 'SetMark',
	qq/"\cX\@c\@"/, 'SetMark',
	qq/"\cX\@c "/,  'SetMark',
	qq/"\cX\@m\\*"/,        'DoMetaVersion',
	'C-y',    'Yank',
	'C-z',    'Suspend',
	'C-\\',   'Ding',
	'C-^',    'Ding',
	'C-_',    'Undo',
	'DEL',  ($inDOS ?
		 'BackwardKillWord' : # <Control>+<Backspace>
		 'BackwardDeleteChar'
	),
	'M-<',    'BeginningOfHistory',
	'M->',    'EndOfHistory',
	'M-DEL',  'BackwardKillWord',
	'M-C-h',  'BackwardKillWord',
	'M-C-j',  'ViInput',
	'M-C-v',  'QuotedInsert',
	'M-b',    'BackwardWord',
	'M-c',    'CapitalizeWord',
	'M-d',    'KillWord',
	'M-f',    'ForwardWord',
	'M-h',    'PrintHistory',
	'M-l',    'DownCaseWord',
	'M-r',    'RevertLine',
	'M-t',    'TransposeWords',
	'M-u',    'UpcaseWord',
	'M-v',    'HistorySearchBackward',
	'M-y',    'YankPop',
	"M-?",    'PossibleCompletions',
	'M-~',    'TildeExpand',
	"M-TAB",  'TabInsert',
	'M-#',    'SaveLine',
	qq/"\e[A"/,  'previous-history',
	qq/"\e[B"/,  'next-history',
	qq/"\e[C"/,  'forward-char',
	qq/"\e[D"/,  'backward-char',
	qq/"\eOA"/,  'previous-history',
	qq/"\eOB"/,  'next-history',
	qq/"\eOC"/,  'forward-char',
	qq/"\eOD"/,  'backward-char',
	qq/"\eOy"/,  'HistorySearchBackward',   # vt: PageUp
	qq/"\eOs"/,  'HistorySearchForward',    # vt: PageDown
	qq/"\e[[A"/, 'previous-history',
	qq/"\e[[B"/, 'next-history',
	qq/"\e[[C"/, 'forward-char',
	qq/"\e[[D"/, 'backward-char',
	qq/"\e[2~"/, 'ToggleInsertMode',        # X: <Insert>
	# Mods: 1 + bitmask: 1 Shift, 2 Alt, 4 Control, 8 (sometimes) Meta
	qq/"\e[2;2~"/,  'YankClipboard',        # <Shift>+<Insert>
	qq/"\e[3;2~"/,  'KillRegionClipboard',  # <Shift>+<Delete>
	#qq/"\0\16"/, 'Undo',                   # <Alt>+<Backspace>
	qq/"\eO5D"/, 'BackwardWord',            # <Ctrl>+<Left arrow>
	qq/"\eO5C"/, 'ForwardWord',             # <Ctrl>+<Right arrow>
	qq/"\e[5D"/, 'BackwardWord',            # <Ctrl>+<Left arrow>
	qq/"\e[5C"/, 'ForwardWord',             # <Ctrl>+<Right arrow>
	qq/"\eO5F"/, 'KillLine',                # <Ctrl>+<End>
	qq/"\e[5F"/, 'KillLine',                # <Ctrl>+<End>
	qq/"\e[4;5~"/, 'KillLine',              # <Ctrl>+<End>
	qq/"\eO5s"/, 'EndOfHistory',            # <Ctrl>+<Page Down>
	qq/"\e[6;5~"/, 'EndOfHistory',          # <Ctrl>+<Page Down>
	qq/"\e[5H"/, 'BackwardKillLine',        # <Ctrl>+<Home>
	qq/"\eO5H"/, 'BackwardKillLine',        # <Ctrl>+<Home>
	qq/"\e[1;5~"/, 'BackwardKillLine',      # <Ctrl>+<Home>
	qq/"\eO5y"/, 'BeginningOfHistory',      # <Ctrl>+<Page Up>
	qq/"\e[5;5y"/, 'BeginningOfHistory',    # <Ctrl>+<Page Up>
	qq/"\e[2;5~"/, 'CopyRegionAsKillClipboard', # <Ctrl>+<Insert>
	qq/"\e[3;5~"/, 'KillWord',              # <Ctrl>+<Delete>

	# XTerm mouse editing (f202/f203 not in mainstream yet):
	# Paste may be:         move f200 STRING f201
	# or               f202 move f200 STRING f201 f203;
	# and Cut may be   f202 move delete f203
	qq/"\e[200~"/, 'BeginPasteGroup',       # Pre-paste
	qq/"\e[201~"/, 'EndPasteGroup',         # Post-paste
	qq/"\e[202~"/, 'BeginEditGroup',        # Pre-edit
	qq/"\e[203~"/, 'EndEditGroup',          # Post-edit

	# OSX xterm:
	# OSX xterm: home \eOH end \eOF delete \e[3~ help \e[28~ f13 \e[25~
	# gray- \eOm gray+ \eOk gray-enter \eOM gray* \eOj gray/ \eOo gray= \eO
	# grayClear \e\e.

	qq/"\eOH"/,   'BeginningOfLine',        # home
	qq/"\eOF"/,   'EndOfLine',              # end

	# HP xterm
	#qq/"\e[A"/,   'PreviousHistory',       # up    arrow
	#qq/"\e[B"/,   'NextHistory',           # down  arrow
	#qq/"\e[C"/,   'ForwardChar',           # right arrow
	#qq/"\e[D"/,   'BackwardChar',          # left  arrow
	qq/"\e[H"/,   'BeginningOfLine',        # home
	#'C-k',        'KillLine',              # clear display
	qq/"\e[5~"/,  'HistorySearchBackward',  # prev
	qq/"\e[6~"/,  'HistorySearchForward',   # next
	qq/"\e[\0"/,  'BeginningOfLine',        # home

	# These contradict:
	($^O =~ /^hp\W?ux/i ? (
	     qq/"\e[1~"/,  'HistorySearchForward', # find
	     qq/"\e[3~"/,  'ToggleInsertMode',     # insert char
	     qq/"\e[4~"/,  'ToggleInsertMode',     # select
	 ) : (          # "Normal" xterm
			qq/"\e[1~"/,  'BeginningOfLine',      # home
			qq/"\e[3~"/,  'DeleteChar',           # delete
			qq/"\e[4~"/,  'EndOfLine',    # end
	 )),

	# hpterm

	(($ENV{'TERM'} and $ENV{'TERM'} eq 'hpterm') ?
	 (
	  qq/"\eA"/,    'PreviousHistory',       # up    arrow
	  qq/"\eB"/,    'NextHistory',           # down  arrow
	  qq/"\eC"/,    'ForwardChar',           # right arrow
	  qq/"\eD"/,    'BackwardChar',          # left  arrow
	  qq/"\eS"/,    'BeginningOfHistory',    # shift up    arrow
	  qq/"\eT"/,    'EndOfHistory',          # shift down  arrow
	  qq/"\e&r1R"/, 'EndOfLine',             # shift right arrow
	  qq/"\e&r1L"/, 'BeginningOfLine',       # shift left  arrow
	  qq/"\eJ"/,    'ClearScreen',           # clear display
	  qq/"\eM"/,    'UnixLineDiscard',       # delete line
	  qq/"\eK"/,    'KillLine',              # clear  line
	  qq/"\eG\eK"/, 'BackwardKillLine',      # shift clear line
	  qq/"\eP"/,    'DeleteChar',            # delete char
	  qq/"\eL"/,    'Yank',                  # insert line
	  qq/"\eQ"/,    'ToggleInsertMode',      # insert char
	  qq/"\eV"/,    'HistorySearchBackward', # prev
	  qq/"\eU"/,    'HistorySearchForward',  # next
	  qq/"\eh"/,    'BeginningOfLine',       # home
	  qq/"\eF"/,    'EndOfLine',             # shift home
	  qq/"\ei"/,    'Suspend',               # shift tab
	 ) :
	 ()
	),
	($inDOS ?
	 (
	  qq/"\0\2"/,  'SetMark',                #   2: <Control>+<Space>
	  qq/"\0\3"/,  'SetMark',                #   3: <Control>+<@>
	  qq/"\0\4"/,  'YankClipboard',          #   4: <Shift>+<Insert>
	  qq/"\0\5"/,  'KillRegionClipboard',    #   5: <Shift>+<Delete>
	  qq/"\0\16"/, 'Undo',                   #  14: <Alt>+<Backspace>
	  qq/"\0\65"/,  'PossibleCompletions',   #  53: <Alt>+</>
	  qq/"\0\107"/, 'BeginningOfLine',       #  71: <Home>
	  qq/"\0\110"/, 'previous-history',      #  72: <Up arrow>
	  qq/"\0\111"/, 'HistorySearchBackward', #  73: <Page Up>
	  qq/"\0\113"/, 'backward-char',         #  75: <Left arrow>
	  qq/"\0\115"/, 'forward-char',          #  77: <Right arrow>
	  qq/"\0\117"/, 'EndOfLine',             #  79: <End>
	  qq/"\0\120"/, 'next-history',          #  80: <Down arrow>
	  qq/"\0\121"/, 'HistorySearchForward',  #  81: <Page Down>
	  qq/"\0\122"/, 'ToggleInsertMode',      #  82: <Insert>
	  qq/"\0\123"/, 'DeleteChar',            #  83: <Delete>
	  qq/"\0\163"/, 'BackwardWord',          # 115: <Ctrl>+<Left arrow>
	  qq/"\0\164"/, 'ForwardWord',           # 116: <Ctrl>+<Right arrow>
	  qq/"\0\165"/, 'KillLine',              # 117: <Ctrl>+<End>
	  qq/"\0\166"/, 'EndOfHistory',          # 118: <Ctrl>+<Page Down>
	  qq/"\0\167"/, 'BackwardKillLine',      # 119: <Ctrl>+<Home>
	  qq/"\0\204"/, 'BeginningOfHistory',    # 132: <Ctrl>+<Page Up>
	  qq/"\0\x92"/, 'CopyRegionAsKillClipboard', # 146: <Ctrl>+<Insert>
	  qq/"\0\223"/, 'KillWord',              # 147: <Ctrl>+<Delete>
	  qq/"\0#"/, 'PrintHistory',             # Alt-H
	 )
	 : ( 'C-@',     'Ding')
	)
	);
    return $keymap;
}

=head2 KeymapVi

vi input-mode key bindings

=cut

sub KeymapVi($$) {
    my ($fn, $keymap) = @_;
    # Vi input mode.
    &$fn($keymap, 'SelfInsert', 'vi_keymap',

	 "\e",   'ViEndInsert',
	 'C-c',  'Interrupt',
	 'C-h',  'BackwardDeleteChar',
	 'C-u',  'UnixLineDiscard',
	 'C-v',  'QuotedInsert',
	 'C-w',  'UnixWordRubout',
	 'DEL',  'BackwardDeleteChar',
	 "\n",   'ViAcceptInsert',
	 "\r",   'ViAcceptInsert',
	);
    return $keymap;
};

=head2 KeymapVicmd

vi command-mode key bindings

=cut

sub KeymapVicmd($$) {
    my ($fn, $keymap, $inDOS) = @_;
    &$fn($keymap, 'Ding', 'vicmd_keymap',

	 'C-c',  'Interrupt',
	 'C-e',  'EmacsEditingMode',
	 'C-h',  'ViMoveCursor',
	 'C-l',  'ClearScreen',
	 "\n",   'ViAcceptLine',
	 "\r",   'ViAcceptLine',

	 ' ',    'ViMoveCursor',
	 '#',    'SaveLine',
	 '$',    'ViMoveCursor',
	 '%',    'ViMoveCursor',
	 '*',    'ViInsertPossibleCompletions',
	 '+',    'NextHistory',
	 ',',    'ViMoveCursor',
	 '-',    'PreviousHistory',
	 '.',    'ViRepeatLastCommand',
	 '/',    'ViSearch',

	 '0',    'ViMoveCursor',
	 '1',    'ViDigit',
	 '2',    'ViDigit',
	 '3',    'ViDigit',
	 '4',    'ViDigit',
	 '5',    'ViDigit',
	 '6',    'ViDigit',
	 '7',    'ViDigit',
	 '8',    'ViDigit',
	 '9',    'ViDigit',

	 ';',    'ViMoveCursor',
	 '=',    'ViPossibleCompletions',
	 '?',    'ViSearch',

	 'A',    'ViAppendLine',
	 'B',    'ViMoveCursor',
	 'C',    'ViChangeLine',
	 'D',    'ViDeleteLine',
	 'E',    'ViMoveCursor',
	 'F',    'ViMoveCursor',
	 'G',    'ViHistoryLine',
	 'H',    'PrintHistory',
	 'I',    'ViBeginInput',
	 'N',    'ViRepeatSearch',
	 'P',    'ViPutBefore',
	 'R',    'ViReplaceMode',
	 'S',    'ViChangeEntireLine',
	 'T',    'ViMoveCursor',
	 'U',    'ViUndoAll',
	 'W',    'ViMoveCursor',
	 'X',    'ViBackwardDeleteChar',
	 'Y',    'ViYankLine',

	 '\\',   'ViComplete',
	 '^',    'ViMoveCursor',

	 'a',    'ViAppend',
	 'b',    'ViMoveCursor',
	 'c',    'ViChange',
	 'd',    'ViDelete',
	 'e',    'ViMoveCursor',
	 'f',    'ViMoveCursorFind',
	 'h',    'ViMoveCursor',
	 'i',    'ViInput',
	 'j',    'NextHistory',
	 'k',    'PreviousHistory',
	 'l',    'ViMoveCursor',
	 'n',    'ViRepeatSearch',
	 'p',    'ViPut',
	 'r',    'ViReplaceChar',
	 's',    'ViChangeChar',
	 't',    'ViMoveCursorTo',
	 'u',    'ViUndo',
	 'w',    'ViMoveCursor',
	 'x',    'ViDeleteChar',
	 'y',    'ViYank',

	 '|',    'ViMoveCursor',
	 '~',    'ViToggleCase',

	 (($inDOS
	   and (not $ENV{'TERM'} or $ENV{'TERM'} !~ /^(vt|xterm)/i)) ?
	  (
	   qq/"\0\110"/, 'PreviousHistory',     # 72: <Up arrow>
	   qq/"\0\120"/, 'NextHistory',         # 80: <Down arrow>
	   qq/"\0\113"/, 'BackwardChar',        # 75: <Left arrow>
	   qq/"\0\115"/, 'ForwardChar',         # 77: <Right arrow>
	   "\e",         'ViCommandMode',
	  ) :

	  (('M-C-j','EmacsEditingMode'), # Conflicts with \e otherwise
	   (($ENV{'TERM'} and $ENV{'TERM'} eq 'hpterm') ?
	    (
	     qq/"\eA"/,    'PreviousHistory',   # up    arrow
	     qq/"\eB"/,    'NextHistory',       # down  arrow
	     qq/"\eC"/,    'ForwardChar',       # right arrow
	     qq/"\eD"/,    'BackwardChar',      # left  arrow
	     qq/"\e\\*"/,  'ViAfterEsc',
	    ) :

	    # Default
	    (
	     qq/"\e[A"/,   'PreviousHistory',    # up    arrow
	     qq/"\e[B"/,   'NextHistory',        # down  arrow
	     qq/"\e[C"/,   'ForwardChar',        # right arrow
	     qq/"\e[D"/,   'BackwardChar',       # left  arrow
	     qq/"\e\\*"/,  'ViAfterEsc',
	     qq/"\e[\\*"/, 'ViAfterEsc',
	    )
	   ))),
	);
}

=head2 KeymapVipos

I<vi> positioning commands suffixed to I<vi> commands like C<d>.

=cut

sub KeymapVipos($$$) {
    my ($fn, $keymap, $inDOS) = @_;

    &$fn($keymap, 'ViNonPosition', 'vipos_keymap',

	 '^',    'ViFirstWord',
	 '0',    'BeginningOfLine',
	 '1',    'ViDigit',
	 '2',    'ViDigit',
	 '3',    'ViDigit',
	 '4',    'ViDigit',
	 '5',    'ViDigit',
	 '6',    'ViDigit',
	 '7',    'ViDigit',
	 '8',    'ViDigit',
	 '9',    'ViDigit',
	 '$',    'EndOfLine',
	 'h',    'BackwardChar',
	 'l',    'ForwardChar',
	 ' ',    'ForwardChar',
	 'C-h',  'BackwardChar',
	 'f',    'ViForwardFindChar',
	 'F',    'ViBackwardFindChar',
	 't',    'ViForwardToChar',
	 'T',    'ViBackwardToChar',
	 ';',    'ViRepeatFindChar',
	 ',',    'ViInverseRepeatFindChar',
	 '%',    'ViFindMatchingParens',
	 '|',    'ViMoveToColumn',

	 # Arrow keys
	 ($inDOS ?
	  (
	   qq/"\0\115"/, 'ForwardChar',         # 77: <Right arrow>
	   qq/"\0\113"/, 'BackwardChar',        # 75: <Left arrow>
	   "\e",         'ViPositionEsc',
	  ) :

	  ($ENV{'TERM'} and $ENV{'TERM'} eq 'hpterm') ?
	  (
	   qq/"\eC"/,    'ForwardChar',         # right arrow
	   qq/"\eD"/,    'BackwardChar',        # left  arrow
	   qq/"\e\\*"/,  'ViPositionEsc',
	  ) :

	  # Default
	  (
	   qq/"\e[C"/,   'ForwardChar',          # right arrow
	   qq/"\e[D"/,   'BackwardChar',         # left  arrow
	   qq/"\e\\*"/,  'ViPositionEsc',
	   qq/"\e[\\*"/, 'ViPositionEsc',
	  )
	 ),
	);
}

=head2 KeymapVisearch

vi search string input mode for C</> and C<?>.

=cut

sub KeymapVisearch($$) {
    my ($fn, $keymap) = @_;
    &$fn($keymap, 'SelfInsert', 'visearch_keymap',

	 "\e",   'Ding',
	 'C-c',  'Interrupt',
	 'C-h',  'ViSearchBackwardDeleteChar',
	 'C-w',  'UnixWordRubout',
	 'C-u',  'UnixLineDiscard',
	 'C-v',  'QuotedInsert',
	 'DEL',  'ViSearchBackwardDeleteChar',
	 "\n",   'ViEndSearch',
	 "\r",   'ViEndSearch',
	);
}

=head1 SEE ALSO

L<Term::ReadLine::Perl5>

=cut

1;
