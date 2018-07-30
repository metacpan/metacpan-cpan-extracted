if {![catch {package require Tk}]} {
    puts {ok1}
    puts $tcl_version
}
if {![catch {package require snit}]} {
    puts {ok2}
}
if {![catch {package require tklib}]} {
    puts {ok3}
}
if {![catch {package require tile}]} {
    puts {ok4}
}
exit
