package Mozilla::DOM;

# $Id: DOM.pm,v 1.22 2008-07-06 21:28:22 slanning Exp $

use 5.008;
use strict;
use warnings;

require DynaLoader;
our @ISA = qw(DynaLoader);

our $VERSION = '0.23';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

__PACKAGE__->bootstrap($VERSION);

=begin comment

Steps to do for each release:

0) make sure ChangeLog, TODO, and MANIFEST are up to date
1) make sure that Mozilla::DOM and Gtk2::MozEmbed build
    make realclean
    perl Makefile.PL
    make
    make test
    sudo make install
2) Try some examples in examples directory.
3) create the distribution tarball (Mozilla-DOM-0.vv.tar.gz)
    make dist
4) move dist tarball to `releases' directory
5) commit to CVS and tag release
    cvs commit
    cvs tag rel-0_vv-yyyy-mm-dd
6) increment $VERSION above
7) upload tarball to PAUSE at https://pause.perl.org/

=end comment

=cut

# -----------------------------------------------------------------------------

package Mozilla::DOM::Supports;

# every interface inherits from this eventually

# -----------------------------------------------------------------------------

package Mozilla::DOM::AbstractView;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::DocumentView;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Event;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant CAPTURING_PHASE => 1;
use constant AT_TARGET       => 2;
use constant BUBBLING_PHASE  => 3;

our %EXPORT_TAGS = (
    phases => [qw(
        CAPTURING_PHASE
	AT_TARGET
	BUBBLING_PHASE
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSEvent;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant MOUSEDOWN => 1;
use constant MOUSEUP => 2;
use constant MOUSEOVER => 4;
use constant MOUSEOUT => 8;
use constant MOUSEMOVE => 16;
use constant MOUSEDRAG => 32;
use constant CLICK => 64;
use constant DBLCLICK => 128;
use constant KEYDOWN => 256;
use constant KEYUP => 512;
use constant KEYPRESS => 1024;
use constant DRAGDROP => 2048;
use constant FOCUS => 4096;
use constant BLUR => 8192;
use constant SELECT => 16384;
use constant CHANGE => 32768;
use constant RESET => 65536;
use constant SUBMIT => 131072;
use constant SCROLL => 262144;
use constant LOAD => 524288;
use constant UNLOAD => 1048576;
use constant XFER_DONE => 2097152;
use constant ABORT => 4194304;
use constant ERROR => 8388608;
use constant LOCATE => 16777216;
use constant MOVE => 33554432;
use constant RESIZE => 67108864;
use constant FORWARD => 134217728;
use constant HELP => 268435456;
use constant BACK => 536870912;
use constant TEXT => 1073741824;
use constant ALT_MASK => 1;
use constant CONTROL_MASK => 2;
use constant SHIFT_MASK => 4;
use constant META_MASK => 8;

our %EXPORT_TAGS = (
    events => [qw(
        MOUSEDOWN
        MOUSEUP
        MOUSEOVER
        MOUSEOUT
        MOUSEMOVE
        MOUSEDRAG
        CLICK
        DBLCLICK
        KEYDOWN
        KEYUP
        KEYPRESS
        DRAGDROP
        FOCUS
        BLUR
        SELECT
        CHANGE
        RESET
        SUBMIT
        SCROLL
        LOAD
        UNLOAD
        XFER_DONE
        ABORT
        ERROR
        LOCATE
        MOVE
        RESIZE
        FORWARD
        HELP
        BACK
        TEXT
        ALT_MASK
        CONTROL_MASK
        SHIFT_MASK
        META_MASK
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::UIEvent;

our @ISA = qw(Mozilla::DOM::Event);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSUIEvent;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant SCROLL_PAGE_DOWN => 32768;
our @EXPORT_OK = qw(SCROLL_PAGE_DOWN);

# -----------------------------------------------------------------------------

package Mozilla::DOM::DocumentEvent;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::MouseEvent;

our @ISA = qw(Mozilla::DOM::UIEvent);

# -----------------------------------------------------------------------------

package Mozilla::DOM::KeyEvent;

our @ISA = qw(Mozilla::DOM::UIEvent Exporter);

use constant DOM_VK_CANCEL => 3;
use constant DOM_VK_HELP => 6;
use constant DOM_VK_BACK_SPACE => 8;
use constant DOM_VK_TAB => 9;
use constant DOM_VK_CLEAR => 12;
use constant DOM_VK_RETURN => 13;
use constant DOM_VK_ENTER => 14;
use constant DOM_VK_SHIFT => 16;
use constant DOM_VK_CONTROL => 17;
use constant DOM_VK_ALT => 18;
use constant DOM_VK_PAUSE => 19;
use constant DOM_VK_CAPS_LOCK => 20;
use constant DOM_VK_ESCAPE => 27;
use constant DOM_VK_SPACE => 32;
use constant DOM_VK_PAGE_UP => 33;
use constant DOM_VK_PAGE_DOWN => 34;
use constant DOM_VK_END => 35;
use constant DOM_VK_HOME => 36;
use constant DOM_VK_LEFT => 37;
use constant DOM_VK_UP => 38;
use constant DOM_VK_RIGHT => 39;
use constant DOM_VK_DOWN => 40;
use constant DOM_VK_PRINTSCREEN => 44;
use constant DOM_VK_INSERT => 45;
use constant DOM_VK_DELETE => 46;
use constant DOM_VK_0 => 48;
use constant DOM_VK_1 => 49;
use constant DOM_VK_2 => 50;
use constant DOM_VK_3 => 51;
use constant DOM_VK_4 => 52;
use constant DOM_VK_5 => 53;
use constant DOM_VK_6 => 54;
use constant DOM_VK_7 => 55;
use constant DOM_VK_8 => 56;
use constant DOM_VK_9 => 57;
use constant DOM_VK_SEMICOLON => 59;
use constant DOM_VK_EQUALS => 61;
use constant DOM_VK_A => 65;
use constant DOM_VK_B => 66;
use constant DOM_VK_C => 67;
use constant DOM_VK_D => 68;
use constant DOM_VK_E => 69;
use constant DOM_VK_F => 70;
use constant DOM_VK_G => 71;
use constant DOM_VK_H => 72;
use constant DOM_VK_I => 73;
use constant DOM_VK_J => 74;
use constant DOM_VK_K => 75;
use constant DOM_VK_L => 76;
use constant DOM_VK_M => 77;
use constant DOM_VK_N => 78;
use constant DOM_VK_O => 79;
use constant DOM_VK_P => 80;
use constant DOM_VK_Q => 81;
use constant DOM_VK_R => 82;
use constant DOM_VK_S => 83;
use constant DOM_VK_T => 84;
use constant DOM_VK_U => 85;
use constant DOM_VK_V => 86;
use constant DOM_VK_W => 87;
use constant DOM_VK_X => 88;
use constant DOM_VK_Y => 89;
use constant DOM_VK_Z => 90;
use constant DOM_VK_CONTEXT_MENU => 93;
use constant DOM_VK_NUMPAD0 => 96;
use constant DOM_VK_NUMPAD1 => 97;
use constant DOM_VK_NUMPAD2 => 98;
use constant DOM_VK_NUMPAD3 => 99;
use constant DOM_VK_NUMPAD4 => 100;
use constant DOM_VK_NUMPAD5 => 101;
use constant DOM_VK_NUMPAD6 => 102;
use constant DOM_VK_NUMPAD7 => 103;
use constant DOM_VK_NUMPAD8 => 104;
use constant DOM_VK_NUMPAD9 => 105;
use constant DOM_VK_MULTIPLY => 106;
use constant DOM_VK_ADD => 107;
use constant DOM_VK_SEPARATOR => 108;
use constant DOM_VK_SUBTRACT => 109;
use constant DOM_VK_DECIMAL => 110;
use constant DOM_VK_DIVIDE => 111;
use constant DOM_VK_F1 => 112;
use constant DOM_VK_F2 => 113;
use constant DOM_VK_F3 => 114;
use constant DOM_VK_F4 => 115;
use constant DOM_VK_F5 => 116;
use constant DOM_VK_F6 => 117;
use constant DOM_VK_F7 => 118;
use constant DOM_VK_F8 => 119;
use constant DOM_VK_F9 => 120;
use constant DOM_VK_F10 => 121;
use constant DOM_VK_F11 => 122;
use constant DOM_VK_F12 => 123;
use constant DOM_VK_F13 => 124;
use constant DOM_VK_F14 => 125;
use constant DOM_VK_F15 => 126;
use constant DOM_VK_F16 => 127;
use constant DOM_VK_F17 => 128;
use constant DOM_VK_F18 => 129;
use constant DOM_VK_F19 => 130;
use constant DOM_VK_F20 => 131;
use constant DOM_VK_F21 => 132;
use constant DOM_VK_F22 => 133;
use constant DOM_VK_F23 => 134;
use constant DOM_VK_F24 => 135;
use constant DOM_VK_NUM_LOCK => 144;
use constant DOM_VK_SCROLL_LOCK => 145;
use constant DOM_VK_COMMA => 188;
use constant DOM_VK_PERIOD => 190;
use constant DOM_VK_SLASH => 191;
use constant DOM_VK_BACK_QUOTE => 192;
use constant DOM_VK_OPEN_BRACKET => 219;
use constant DOM_VK_BACK_SLASH => 220;
use constant DOM_VK_CLOSE_BRACKET => 221;
use constant DOM_VK_QUOTE => 222;
use constant DOM_VK_META => 224;

our %EXPORT_TAGS = (
    keycodes => [qw(
        DOM_VK_CANCEL
        DOM_VK_HELP
        DOM_VK_BACK_SPACE
        DOM_VK_TAB
        DOM_VK_CLEAR
        DOM_VK_RETURN
        DOM_VK_ENTER
        DOM_VK_SHIFT
        DOM_VK_CONTROL
        DOM_VK_ALT
        DOM_VK_PAUSE
        DOM_VK_CAPS_LOCK
        DOM_VK_ESCAPE
        DOM_VK_SPACE
        DOM_VK_PAGE_UP
        DOM_VK_PAGE_DOWN
        DOM_VK_END
        DOM_VK_HOME
        DOM_VK_LEFT
        DOM_VK_UP
        DOM_VK_RIGHT
        DOM_VK_DOWN
        DOM_VK_PRINTSCREEN
        DOM_VK_INSERT
        DOM_VK_DELETE
        DOM_VK_0
        DOM_VK_1
        DOM_VK_2
        DOM_VK_3
        DOM_VK_4
        DOM_VK_5
        DOM_VK_6
        DOM_VK_7
        DOM_VK_8
        DOM_VK_9
        DOM_VK_SEMICOLON
        DOM_VK_EQUALS
        DOM_VK_A
        DOM_VK_B
        DOM_VK_C
        DOM_VK_D
        DOM_VK_E
        DOM_VK_F
        DOM_VK_G
        DOM_VK_H
        DOM_VK_I
        DOM_VK_J
        DOM_VK_K
        DOM_VK_L
        DOM_VK_M
        DOM_VK_N
        DOM_VK_O
        DOM_VK_P
        DOM_VK_Q
        DOM_VK_R
        DOM_VK_S
        DOM_VK_T
        DOM_VK_U
        DOM_VK_V
        DOM_VK_W
        DOM_VK_X
        DOM_VK_Y
        DOM_VK_Z
        DOM_VK_CONTEXT_MENU
        DOM_VK_NUMPAD0
        DOM_VK_NUMPAD1
        DOM_VK_NUMPAD2
        DOM_VK_NUMPAD3
        DOM_VK_NUMPAD4
        DOM_VK_NUMPAD5
        DOM_VK_NUMPAD6
        DOM_VK_NUMPAD7
        DOM_VK_NUMPAD8
        DOM_VK_NUMPAD9
        DOM_VK_MULTIPLY
        DOM_VK_ADD
        DOM_VK_SEPARATOR
        DOM_VK_SUBTRACT
        DOM_VK_DECIMAL
        DOM_VK_DIVIDE
        DOM_VK_F1
        DOM_VK_F2
        DOM_VK_F3
        DOM_VK_F4
        DOM_VK_F5
        DOM_VK_F6
        DOM_VK_F7
        DOM_VK_F8
        DOM_VK_F9
        DOM_VK_F10
        DOM_VK_F11
        DOM_VK_F12
        DOM_VK_F13
        DOM_VK_F14
        DOM_VK_F15
        DOM_VK_F16
        DOM_VK_F17
        DOM_VK_F18
        DOM_VK_F19
        DOM_VK_F20
        DOM_VK_F21
        DOM_VK_F22
        DOM_VK_F23
        DOM_VK_F24
        DOM_VK_NUM_LOCK
        DOM_VK_SCROLL_LOCK
        DOM_VK_COMMA
        DOM_VK_PERIOD
        DOM_VK_SLASH
        DOM_VK_BACK_QUOTE
        DOM_VK_OPEN_BRACKET
        DOM_VK_BACK_SLASH
        DOM_VK_CLOSE_BRACKET
        DOM_VK_QUOTE
        DOM_VK_META
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::MutationEvent;

our @ISA = qw(Mozilla::DOM::Event Exporter);

use constant MODIFICATION => 1;
use constant ADDITION     => 2;
use constant REMOVAL      => 3;

our %EXPORT_TAGS = (
    changes => [qw(
        MODIFICATION
	ADDITION
	REMOVAL
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::EventTarget;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::EventListener;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Window;

our @ISA = qw(Mozilla::DOM::Supports);

sub GetFrames {
    my $self = shift;
    my $windowcollection = $self->GetFrames_windowcollection;
    if (wantarray) {
        my $len = $windowcollection->GetLength;
        if ($len) {
            return map { $windowcollection->Item($_) } 0 .. $len - 1;
        } else {
            return ();
        }
    } else {
        return $windowcollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::Window2;

our @ISA = qw(Mozilla::DOM::Window);

# -----------------------------------------------------------------------------

package Mozilla::DOM::WindowInternal;

our @ISA = qw(Mozilla::DOM::Window2);

# -----------------------------------------------------------------------------

package Mozilla::DOM::WindowCollection;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Node;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant ELEMENT_NODE                => 1;
use constant ATTRIBUTE_NODE              => 2;
use constant TEXT_NODE                   => 3;
use constant CDATA_SECTION_NODE          => 4;
use constant ENTITY_REFERENCE_NODE       => 5;
use constant ENTITY_NODE                 => 6;
use constant PROCESSING_INSTRUCTION_NODE => 7;
use constant COMMENT_NODE                => 8;
use constant DOCUMENT_NODE               => 9;
use constant DOCUMENT_TYPE_NODE          => 10;
use constant DOCUMENT_FRAGMENT_NODE      => 11;
use constant NOTATION_NODE               => 12;

our %EXPORT_TAGS = (
    types => [qw(
        ELEMENT_NODE
        ATTRIBUTE_NODE
        TEXT_NODE
        CDATA_SECTION_NODE
        ENTITY_REFERENCE_NODE
        ENTITY_NODE
        PROCESSING_INSTRUCTION_NODE
        COMMENT_NODE
        DOCUMENT_NODE
        DOCUMENT_TYPE_NODE
        DOCUMENT_FRAGMENT_NODE
        NOTATION_NODE
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

sub GetChildNodes {
    my $self = shift;
    my $nodelist = $self->GetChildNodes_nodelist;
    if (wantarray) {
        my $len = $nodelist->GetLength;
        if ($len) {
            return map { $nodelist->Item($_) } 0 .. $len - 1;
        } else {
            return ();
        }
    } else {
        return $nodelist;
    }
}

sub GetAttributes {
    my $self = shift;
    my $namednodemap = $self->GetAttributes_namednodemap;
    if (wantarray) {
        my $len = $namednodemap->GetLength;
        if ($len) {
            my @attrs = ();
            my $iid = Mozilla::DOM::Attr->GetIID;
            for my $i (0 .. $len - 1) {
                my $attr = $namednodemap->Item($i);
                push @attrs, $attr->QueryInterface($iid);
            }
            return @attrs;
        } else {
            return ();
        }
    } else {
        return $namednodemap;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::NodeList;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NamedNodeMap;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSDocument;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Document;

our @ISA = qw(Mozilla::DOM::Node);

sub GetElementsByTagName {
    my $self = shift;
    my $nodelist = $self->GetElementsByTagName_nodelist(@_);
    if (wantarray) {
        my $len = $nodelist->GetLength;
        if ($len) {
            my @elements = ();
            my $iid = Mozilla::DOM::Element->GetIID;
            for my $i (0 .. $len - 1) {
                my $node = $nodelist->Item($i);
                push @elements, $node->QueryInterface($iid);
            }
            return @elements;
        } else {
            return ();
        }
    } else {
        return $nodelist;
    }
}

sub GetElementsByTagNameNS {
    my $self = shift;
    my $nodelist = $self->GetElementsByTagNameNS_nodelist(@_);
    if (wantarray) {
        my $len = $nodelist->GetLength;
        if ($len) {
            my @elements = ();
            my $iid = Mozilla::DOM::Element->GetIID;
            for my $i (0 .. $len - 1) {
                my $node = $nodelist->Item($i);
                push @elements, $node->QueryInterface($iid);
            }
            return @elements;
        } else {
            return ();
        }
    } else {
        return $nodelist;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::Element;

our @ISA = qw(Mozilla::DOM::Node);

sub GetElementsByTagName {
    my $self = shift;
    my $nodelist = $self->GetElementsByTagName_nodelist(@_);
    if (wantarray) {
        my $len = $nodelist->GetLength;
        if ($len) {
            my @elements = ();
            my $iid = Mozilla::DOM::Element->GetIID;
            for my $i (0 .. $len - 1) {
                my $node = $nodelist->Item($i);
                push @elements, $node->QueryInterface($iid);
            }
            return @elements;
        } else {
            return ();
        }
    } else {
        return $nodelist;
    }
}

sub GetElementsByTagNameNS {
    my $self = shift;
    my $nodelist = $self->GetElementsByTagNameNS_nodelist(@_);
    if (wantarray) {
        my $len = $nodelist->GetLength;
        if ($len) {
            my @elements = ();
            my $iid = Mozilla::DOM::Element->GetIID;
            for my $i (0 .. $len - 1) {
                my $node = $nodelist->Item($i);
                push @elements, $node->QueryInterface($iid);
            }
            return @elements;
        } else {
            return ();
        }
    } else {
        return $nodelist;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::Entity;

our @ISA = qw(Mozilla::DOM::Node);

# -----------------------------------------------------------------------------

package Mozilla::DOM::EntityReference;

our @ISA = qw(Mozilla::DOM::Node);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Attr;

our @ISA = qw(Mozilla::DOM::Node);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Notation;

our @ISA = qw(Mozilla::DOM::Node);

# -----------------------------------------------------------------------------

package Mozilla::DOM::ProcessingInstruction;

our @ISA = qw(Mozilla::DOM::Node);

# -----------------------------------------------------------------------------

package Mozilla::DOM::CDATASection;

our @ISA = qw(Mozilla::DOM::Text);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Comment;

our @ISA = qw(Mozilla::DOM::CharacterData);

# -----------------------------------------------------------------------------

package Mozilla::DOM::CharacterData;

our @ISA = qw(Mozilla::DOM::Node);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Text;

our @ISA = qw(Mozilla::DOM::CharacterData);

# -----------------------------------------------------------------------------

package Mozilla::DOM::DocumentFragment;

our @ISA = qw(Mozilla::DOM::Node);

# -----------------------------------------------------------------------------

package Mozilla::DOM::DocumentRange;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::DocumentType;

our @ISA = qw(Mozilla::DOM::Node);

sub GetEntities {
    my $self = shift;
    my $namednodemap = $self->GetEntities_namednodemap;
    if (wantarray) {
        my $len = $namednodemap->GetLength;
        if ($len) {
            my @entities = ();
            my $iid = Mozilla::DOM::Entity->GetIID;
            for my $i (0 .. $len - 1) {
                my $entity = $namednodemap->Item($i);
                push @entities, $entity->QueryInterface($iid);
            }
            return @entities;
        } else {
            return ();
        }
    } else {
        return $namednodemap;
    }
}

sub GetNotations {
    my $self = shift;
    my $namednodemap = $self->GetNotations_namednodemap;
    if (wantarray) {
        my $len = $namednodemap->GetLength;
        if ($len) {
            my @notations = ();
            my $iid = Mozilla::DOM::Notation->GetIID;
            for my $i (0 .. $len - 1) {
                my $notation = $namednodemap->Item($i);
                push @notations, $notation->QueryInterface($iid);
            }
            return @notations;
        } else {
            return ();
        }
    } else {
        return $namednodemap;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::DOMImplementation;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::DOMException;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant INDEX_SIZE_ERR => 1;
use constant DOMSTRING_SIZE_ERR => 2;
use constant HIERARCHY_REQUEST_ERR => 3;
use constant WRONG_DOCUMENT_ERR => 4;
use constant INVALID_CHARACTER_ERR => 5;
use constant NO_DATA_ALLOWED_ERR => 6;
use constant NO_MODIFICATION_ALLOWED_ERR => 7;
use constant NOT_FOUND_ERR => 8;
use constant NOT_SUPPORTED_ERR => 9;
use constant INUSE_ATTRIBUTE_ERR => 10;
use constant INVALID_STATE_ERR => 11;
use constant SYNTAX_ERR => 12;
use constant INVALID_MODIFICATION_ERR => 13;
use constant NAMESPACE_ERR => 14;
use constant INVALID_ACCESS_ERR => 15;

our %EXPORT_TAGS = (
    errcodes => [qw(
        INDEX_SIZE_ERR
        DOMSTRING_SIZE_ERR
        HIERARCHY_REQUEST_ERR
        WRONG_DOCUMENT_ERR
        INVALID_CHARACTER_ERR
        NO_DATA_ALLOWED_ERR
        NO_MODIFICATION_ALLOWED_ERR
        NOT_FOUND_ERR
        NOT_SUPPORTED_ERR
        INUSE_ATTRIBUTE_ERR
        INVALID_STATE_ERR
        SYNTAX_ERR
        INVALID_MODIFICATION_ERR
        NAMESPACE_ERR
        INVALID_ACCESS_ERR
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::Selection;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Range;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant START_TO_START          => 0;
use constant START_TO_END            => 1;
use constant END_TO_END              => 2;
use constant END_TO_START            => 3;

our %EXPORT_TAGS = (
    how => [qw(
        START_TO_START
        START_TO_END
        END_TO_END
        END_TO_START
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSRange;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant NODE_BEFORE            => 0;
use constant NODE_AFTER             => 1;
use constant NODE_BEFORE_AND_AFTER  => 2;
use constant NODE_INSIDE            => 3;

our %EXPORT_TAGS = (
    compare => [qw(
        NODE_BEFORE
        NODE_AFTER
        NODE_BEFORE_AND_AFTER
        NODE_INSIDE
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::History;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Location;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Navigator;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::Screen;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::WebBrowser;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::WebNavigation;

our @ISA = qw(Mozilla::DOM::Supports Exporter);

use constant LOAD_FLAGS_MASK => 65535;
use constant LOAD_FLAGS_NONE => 0;
use constant LOAD_FLAGS_IS_REFRESH => 16;
use constant LOAD_FLAGS_IS_LINK => 32;
use constant LOAD_FLAGS_BYPASS_HISTORY => 64;
use constant LOAD_FLAGS_REPLACE_HISTORY => 128;
use constant LOAD_FLAGS_BYPASS_CACHE => 256;
use constant LOAD_FLAGS_BYPASS_PROXY => 512;
use constant LOAD_FLAGS_CHARSET_CHANGE => 1024;
use constant STOP_NETWORK => 1;
use constant STOP_CONTENT => 2;
use constant STOP_ALL => 3;

our %EXPORT_TAGS = (
    flags => [qw(
        LOAD_FLAGS_MASK
        LOAD_FLAGS_NONE
        LOAD_FLAGS_IS_REFRESH
        LOAD_FLAGS_IS_LINK
        LOAD_FLAGS_BYPASS_HISTORY
        LOAD_FLAGS_REPLACE_HISTORY
        LOAD_FLAGS_BYPASS_CACHE
        LOAD_FLAGS_BYPASS_PROXY
        LOAD_FLAGS_CHARSET_CHANGE
        STOP_NETWORK
        STOP_CONTENT
        STOP_ALL
    )],
);
our @EXPORT_OK = map { @$_ } values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = \@EXPORT_OK;

# -----------------------------------------------------------------------------

package Mozilla::DOM::URI;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLAreaElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLDirectoryElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLAnchorElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLAppletElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLBRElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLBaseElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLBaseFontElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLBodyElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLButtonElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLCollection;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLDListElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLDivElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLElement;

our @ISA = qw(Mozilla::DOM::Element);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLEmbedElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLFieldSetElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLFontElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLFrameElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLFormElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

sub GetElements {
    my $self = shift;
    my $htmlcollection = $self->GetElements_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            return map { $htmlcollection->Item($_) } 0 .. $len - 1;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLFrameSetElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLHRElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLHeadElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLHeadingElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLHtmlElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLIFrameElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLImageElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLInputElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLIsIndexElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLLIElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLLabelElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLLegendElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLLinkElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLMapElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

sub GetAreas {
    my $self = shift;
    my $htmlcollection = $self->GetAreas_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            my @areas = ();
            my $iid = Mozilla::DOM::HTMLAreaElement->GetIID;
            for my $i (0 .. $len - 1) {
                my $area = $htmlcollection->Item($i);
                push @areas, $area->QueryInterface($iid);
            }
            return @areas;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLMenuElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLMetaElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLModElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLOListElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLObjectElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLOptGroupElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLOptionElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLOptionsCollection;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLParagraphElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLParamElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLPreElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLQuoteElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLScriptElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLSelectElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

sub GetOptions {
    my $self = shift;
    my $optionscollection = $self->GetOptions_optionscollection;
    if (wantarray) {
        my $len = $optionscollection->GetLength;
        if ($len) {
            my @options = ();
            my $iid = Mozilla::DOM::HTMLOptionElement->GetIID;
            for my $i (0 .. $len - 1) {
                my $option = $optionscollection->Item($i);
                push @options, $option->QueryInterface($iid);
            }
            return @options;
        } else {
            return ();
        }
    } else {
        return $optionscollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLStyleElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTableCaptionElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTableCellElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTableColElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTableElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

sub GetRows {
    my $self = shift;
    my $htmlcollection = $self->GetRows_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            my @rows = ();
            my $iid = Mozilla::DOM::HTMLTableRowElement->GetIID;
            for my $i (0 .. $len - 1) {
                my $row = $htmlcollection->Item($i);
                push @rows, $row->QueryInterface($iid);
            }
            return @rows;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

sub GetTBodies {
    my $self = shift;
    my $htmlcollection = $self->GetTBodies_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            my @bodies = ();
            my $iid = Mozilla::DOM::HTMLElement->GetIID;
            for my $i (0 .. $len - 1) {
                my $body = $htmlcollection->Item($i);
                push @bodies, $body->QueryInterface($iid);
            }
            return @bodies;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTableRowElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

sub GetCells {
    my $self = shift;
    my $htmlcollection = $self->GetCells_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            my @cells = ();
            my $iid = Mozilla::DOM::HTMLTableCellElement->GetIID;
            for my $i (0 .. $len - 1) {
                my $cell = $htmlcollection->Item($i);
                push @cells, $cell->QueryInterface($iid);
            }
            return @cells;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTableSectionElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

sub GetRows {
    my $self = shift;
    my $htmlcollection = $self->GetRows_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            my @rows = ();
            my $iid = Mozilla::DOM::HTMLTableRowElement->GetIID;
            for my $i (0 .. $len - 1) {
                my $row = $htmlcollection->Item($i);
                push @rows, $row->QueryInterface($iid);
            }
            return @rows;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTextAreaElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLTitleElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::HTMLUListElement;

our @ISA = qw(Mozilla::DOM::HTMLElement);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLAnchorElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLAreaElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLButtonElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLDocument;

our @ISA = qw(Mozilla::DOM::Supports);

sub GetEmbeds {
    my $self = shift;
    my $htmlcollection = $self->GetEmbeds_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            return map { $htmlcollection->Item($_) } 0 .. $len - 1;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

sub GetPlugins {
    my $self = shift;
    my $htmlcollection = $self->GetPlugins_htmlcollection;
    if (wantarray) {
        my $len = $htmlcollection->GetLength;
        if ($len) {
            return map { $htmlcollection->Item($_) } 0 .. $len - 1;
        } else {
            return ();
        }
    } else {
        return $htmlcollection;
    }
}

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLFormElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLFrameElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLHRElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLImageElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLInputElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLOptionElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLSelectElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM::NSHTMLTextAreaElement;

our @ISA = qw(Mozilla::DOM::Supports);

# -----------------------------------------------------------------------------

package Mozilla::DOM;

1;

__END__

=head1 NAME

Mozilla::DOM - Perl wrapping of the Mozilla/Gecko DOM

=head1 SYNOPSIS

  # In Makefile.PL (see Gtk2::MozEmbed for an example)
  my $embed = ExtUtils::Depends->new('Mozilla::DOM');
  $embed->set_inc(...);
  ...

  # You also need to compile with C++
  WriteMakefile(
      ...
      CC => 'c++',
      XSOPT => '-C++',
      $embed->get_makefile_vars,
  );

=head1 ABSTRACT

XXX: update this

The current purpose of this module is to wrap DOM event methods
to be used with the L<Gtk2::MozEmbed|Gtk2::MozEmbed> module, which
allows you to use GtkMozEmbed from Perl. GtkMozEmbed in turn
allows you to use Mozilla's Gecko as a Gtk widget. Gtk2::MozEmbed
has signal marshallers which rely on this module to map between
the nsIDOM* interfaces and Gtk-Perl. There's nothing in this module
(as far as I know) that is specific to GtkMozEmbed, however, so other
Perl modules based on Gecko could use this (if they existed).

Future plans include wrapping more DOM interfaces such as nsIWebBrowser
(requiring support in Gtk2::MozEmbed for gtk_moz_embed_get_nsIWebBrowser),
nsIDOMWindow, and nsIDOMDocument. With this, you'd get access to the DOM,
with methods such as GetElementsByTagName. Adding more support for DOM
events would allow finding out more about an event and its targets,
initiating events, and adding listeners. The idea is to then be able to
script a Gecko-based browser from Perl. However, for the moment the
functionality provided by this module probably isn't very useful.

=head1 SEE ALSO

=over 4

=item L<Mozilla::DOM::index|Mozilla::DOM::index>

A list of all the POD files distributed with this module.

=item L<Gtk2::MozEmbed|Gtk2::MozEmbed>

=item L<Mozilla::Mechanize>

A WWW::Mechanize-like module using this module and Gtk2::MozEmbed.

=item DOM Level 3 specification

In particular the sections on Key and Mouse events.

=item F<E<sol>usrE<sol>includeE<sol>mozillaE<sol>gtkembedmozE<sol>gtkmozembed.h>

=item F<E<sol>usrE<sol>includeE<sol>mozillaE<sol>gtkembedmozE<sol>gtkmozembed_internal.h>

The header files for GtkMozEmbed.

=item TestGtkEmbed.cpp

A C++ example of using GtkMozEmbed to make a minimal browser.

=item F<E<sol>usrE<sol>includeE<sol>mozillaE<sol>*.h>

The header files for Mozilla's interfaces. Generally, if a module
is called Mozilla::DOM::Something, the corresponding header file
is named 'nsIDOMSomething.h'. Three exceptions are nsISupports,
nsIWebBrowser, and nsISelection, where the interface name doesn't
include "DOM".

=item L<http:E<sol>E<sol>mozilla.orgE<sol>htmlE<sol>projectsE<sol>embeddingE<sol>PublicAPIs.html>

Description of the Mozilla Public API

=item L<http:E<sol>E<sol>mozilla.orgE<sol>htmlE<sol>projectsE<sol>embeddingE<sol>faq.html>

Gecko Embedding FAQ

=item L<http:E<sol>E<sol>mozilla.orgE<sol>htmlE<sol>unixE<sol>gtk-embedding.html>

GtkMozEmbed: Gtk Mozilla Embedding Widget

=back

=head1 AUTHORS

=over

=item Scott Lanning <slanning@cpan.org>

=back

with a lot of help from Torsten Schoenfeld and Boris Sukholitko
(see Credits)

=head1 COPYRIGHT

Copyright (C) 2005-2007 by Scott Lanning

=cut
