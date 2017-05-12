(* Project-Builder.org module for Augeas                *)
(* Author: Raphael Pinson <raphink@gmail.com>           *)
(* Maintainer: Bruno Cornec <bruno@project-builder.org> *)
(* $Id$                                                 *)
(*                                                      *)
(* This lense for Augeas applies to Project-Builder.org *)
(* configuration files                                  *)
(*                                                      *)
(*  Format: Field Project = Value1 [, Value2, ...]      *)
(*                                                      *)

module ProjectBuilder =
  autoload xfm
  
  let word    = Rx.word
  let ws      = Util.del_ws_tab
  let eol     = Util.eol
  let comment = Util.comment
  let empty   = Util.empty
  let eq      = del /[ \t]*=[ \t]*/ "="
  let comma   = del /[ \t]*,[ \t]*/ ","
  let sto_value = [ label "value" . store /[^ \t\n,]+/ ]

  let record = [ key word . ws . store word
                 . eq
                 . Build.opt_list sto_value comma
                 . (eol|comment)
                 ]

  let lns = ( record | comment | empty )*

  let filter = (incl "/home/bruno/.pbrc") . Util.stdexcl

  let xfm = transform lns filter

(* vim: set syntax=pascal *)
