#ifndef PERLQT_H
#define PERLQT_H

// keep this enum in sync with lib/Qt4/debug.pm

enum Qt4DebugChannel {
    qtdb_none = 0x00,
    qtdb_ambiguous = 0x01,
    qtdb_autoload = 0x02,
    qtdb_calls = 0x04,
    qtdb_gc = 0x08,
    qtdb_virtual = 0x10,
    qtdb_verbose = 0x20,
    qtdb_signals = 0x40,
    qtdb_slots = 0x80,
};

#endif //PERLQT_H
