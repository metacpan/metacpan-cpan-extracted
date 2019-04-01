# Term-YAP
Term-YAP means "Yet Another Pulse for Terminal"

Term::YAP is a Moo based class to implement a "pulse" bar in a terminal. A pulse
bar doesn't actually keep track of progress from any task being executed but at
least shows that the program is working instead of nothing for the end user.

This module started as a shamelessly copy from Term::Pulse project, nowadays it
keeps the same features but with a different implementation.

## How is organized

This project has three Perl classes:

```
lib/
└── Term
    ├── YAP
    │   ├── iThread.pm
    │   └── Process.pm
    └── YAP.pm
```

`Term::YAP` is the superclass inherited by the subclasses `Term::YAP::iThread`
and `Term::YAP::Process`. As their names suggest, their are implementations of
the pulse bar by using ithreads and processes, respectively.

Anyway, both implementations will maintain a parent thread/process, executing
a given task in a separated thread/process, and keeps checking it until
the task is finished.
