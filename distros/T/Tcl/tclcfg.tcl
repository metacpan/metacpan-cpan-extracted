puts "tclsh=[info nameofexecutable]"
set libdir [info library]
catch {
    # As of Tcl 8.7, [info library] is a zipfs path.
    # Use ::tcl::pkgconfig instead (available in Tcl 8.5 and later),
    # see https://wiki.tcl-lang.org/page/Finding+out+tclConfig%2Esh
    set libdir [::tcl::pkgconfig get libdir,install]
}
set dirs [list \
	      [file dirname $libdir] \
	      [file dirname [file dirname $libdir]] \
	      [file join [file dirname [file dirname [info nameofexe]]] lib] \
	      [file join $libdir "tcl$tcl_version"] \
	     ]
foreach dir $dirs {
    if {[file exists [file join $dir tclConfig.sh]]} {
	puts "tclConfig.sh=[file join $dir tclConfig.sh]"
	break
    }
}
puts "tcl_library=$libdir"
puts "tcl_version=$tcl_version"
