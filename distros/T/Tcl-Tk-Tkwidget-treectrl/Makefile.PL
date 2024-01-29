use ExtUtils::MakeMaker;
WriteMakefile(
    VERSION => '2.4.2.6',
    NAME => "Tcl::Tk::Tkwidget::treectrl",
    PREREQ_PM => {
       'Tcl::Tk' => 1.0,
    },
);
