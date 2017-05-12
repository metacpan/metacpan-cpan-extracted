
namespace SOOT {
  // This isn't really checking ->isa('TObject') but whether it's part of the SOOT/ROOT system
  inline bool
  IsTObject(pTHX_ SV* sv)
  {
    return sv_isobject(sv) && hv_exists(SvSTASH((SV*)SvRV(sv)), "isROOT", 6);
  }

} // end namespace SOOT

