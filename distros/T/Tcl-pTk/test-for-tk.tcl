if {![catch {package require Tk}]} {
    puts {ok1}
    puts "TclVersion $tcl_version"
}
if {![catch {package require Tix}]} {
    puts {ok_Tix}
}
# detect tklib existence ('cursor' is a package in tklib)
if {![catch {package require cursor}]} {
    puts {ok3}
}
exit
