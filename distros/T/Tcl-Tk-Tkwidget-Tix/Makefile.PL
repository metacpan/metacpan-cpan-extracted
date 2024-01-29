use ExtUtils::MakeMaker;
WriteMakefile(
    VERSION => '8.4.3.0',
    NAME => "Tcl::Tk::Tkwidget::Tix",
    PREREQ_PM => {
       'Tcl::Tk' => 1.0,
    },
);
