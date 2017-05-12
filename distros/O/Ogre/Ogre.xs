#include <Ogre.h>
#include <string>
#include <set>
#include <vector>

#include "perlOGRE.h"
#include "PerlOGRECallbackManager.h"
#include "PerlOGREFrameListener.h"
#include "PerlOGREWindowEventListener.h"

#include "PerlOGREControllerFunction.h"
#include "PerlOGREControllerValue.h"


// This object manages FrameListeners, WindowEventListeners...
PerlOGRECallbackManager pogreCallbackManager;


// This allows using a wxPerl or Gtk2 window
// as a render window, rather than relying on Ogre
// to create a default render window.
#include "perlOGREGUI.h"


// note: I think these have to come after the includes,
// esp. the gtk+ ones, because otherwise a conflict
// appears in X11/Xlib.h which refers to Font,
// and this is confused with Ogre::Font)
using namespace std;
using namespace Ogre;


// helper functions - should move these to another file

// this is used twice in RaySceneQuery.xs
// Note: see ConfigFile::getSections for a similar example.
// The results here are returned in an aref, each of whose
// items is a hashref whose keys are: distance, movable,
// and worldFragment.
SV * perlOGRE_RaySQ2aref(RaySceneQueryResult& qres) {
    AV *res_av = (AV *) sv_2mortal((SV *) newAV());

    RaySceneQueryResult::const_iterator it;
    RaySceneQueryResult::const_iterator itEnd = qres.end();

    for (it = qres.begin(); it != itEnd; ++it) {
        // go from C++ to Perl SV*
        // note: for some reason, these SV* shouldn't be mortalized
        SV *distance_sv = newSV(0),
           *movable_sv = newSV(0),
           *worldFragment_sv = newSV(0);

        sv_setnv(distance_sv, (Real) (it->distance));

        if (it->movable) {
            MovableObject *mop = it->movable;
            TMOGRE_OUT(movable_sv, mop, MovableObject);
        }
        else {
            movable_sv = &PL_sv_undef;
        }

        if (it->worldFragment) {
            WorldFragment *wfp = it->worldFragment;
            TMOGRE_OUT(worldFragment_sv, wfp, SceneQuery::WorldFragment);
        }
        else {
            worldFragment_sv = &PL_sv_undef;
        }

        // put the SV* into a hash
        HV *entry_hv = (HV *) sv_2mortal((SV *) newHV());
        hv_store(entry_hv, "distance", 8, distance_sv, 0);
        hv_store(entry_hv, "movable", 7, movable_sv, 0);
        hv_store(entry_hv, "worldFragment", 13, worldFragment_sv, 0);

        // push the hash onto the array
        av_push(res_av, newRV((SV *) entry_hv));
    }

    // return the array ref
    return newRV((SV *)res_av);
}

// this is used in RegionSceneQuery
// A bit different than above. The results here are returned in a hashref
// whose keys are: movables and worldFragments. Those are array refs:
// movables = MovableObject*, worldFragments = SceneQuery::WorldFragment*
SV * perlOGRE_SQ2href(SceneQueryResult& qres) {
    // the hashref to return
    HV *res_hv = (HV *) sv_2mortal((SV *) newHV());

    // the movables aref
    SceneQueryResultMovableList::iterator m_itr;
    AV *movables_av = (AV *) sv_2mortal((SV *) newAV());
    for (m_itr = qres.movables.begin(); m_itr != qres.movables.end(); m_itr++) {
        SV *mov_sv = newSV(0);
        TMOGRE_OUT(mov_sv, *m_itr, MovableObject);

        av_push(movables_av, mov_sv);
    }
    hv_store(res_hv, "movables", 8, (SV *) newRV((SV *) movables_av), 0);

    // the worldFragments aref
    SceneQueryResultWorldFragmentList::iterator wf_itr;
    AV *worldFragments_av = (AV *) sv_2mortal((SV *) newAV());
    for (wf_itr = qres.worldFragments.begin(); wf_itr != qres.worldFragments.end(); wf_itr++) {
        SV *wf_sv = newSV(0);
        TMOGRE_OUT(wf_sv, *wf_itr, SceneQuery::WorldFragment);

        av_push(worldFragments_av, wf_sv);
    }
    hv_store(res_hv, "worldFragments", 14, (SV *) newRV((SV *) worldFragments_av), 0);

    // return the hash ref
    return newRV((SV *)res_hv);
}

// note: caller must delete the pointer
PlaneBoundedVolumeList * perlOGRE_aref2PBVL(SV *volumes_sv, const char *caller) {
    if ((!SvROK(volumes_sv)) || (SvTYPE(SvRV(volumes_sv)) != SVt_PVAV)) {
        croak(caller, ": volumes arg must be an array ref\n");
    }

    // turn aref into PlaneBoundedVolumeList
    PlaneBoundedVolumeList *volumes = new PlaneBoundedVolumeList;
    I32 numvolumes = av_len((AV *) SvRV(volumes_sv));
    for (int n = 0; n <= numvolumes; n++) {
        SV *pbv_sv = *av_fetch((AV *)SvRV(volumes_sv), n, 0);
        if (sv_isobject(pbv_sv) && sv_derived_from(pbv_sv, "Ogre::PlaneBoundedVolume")) {
            PlaneBoundedVolume *vol = (PlaneBoundedVolume *) SvIV((SV *) SvRV(pbv_sv));
            volumes->push_back(*vol);
        }
        else {
            croak("Usage: ", caller, ": array ref must contain only Ogre::PlaneBoundedVolume objects\n");
        }
    }

    return volumes;
}



MODULE = Ogre		PACKAGE = Ogre

PROTOTYPES: ENABLE


#ifdef PERLOGRE_HAS_GTK2

static String
Ogre::getWindowHandleString(w)
    SV * w
  PREINIT:
    GtkWidget *widget;
  CODE:
    // for gtk2-perl, object that isa Gtk2::Widget
    if (sv_isobject(ST(1))) {
        TMOGRE_GTKWIDGET_IN(ST(1), widget, Ogre, getWindowHandleString);
    }
    // for wxPerl, (IV) result of GetHandle() on (isa) Wx::Window object
    else if (SvIOK(ST(1))) {
        widget = INT2PTR(GtkWidget *, SvIV(ST(1)));    // T_PTR
    }
    else {
        croak("Usage: Ogre::getWindowHandleString(CLASS, Gtk2::Widget) or (CLASS, integer)\n");
    }

    RETVAL = getWindowHandleString(widget);
  OUTPUT:
    RETVAL

#endif  /* PERLOGRE_HAS_GTK2 */


INCLUDE: perl -e "print qq{INCLUDE: \$_\$/} for <xs/*.xs>" |


BOOT:
    {
	// xxx: Ogre.pm does `require Exporter`, so I don't here,
	// though it's necessary to be loaded before any constants are
	// used; so if the modules are split out and loaded separately,
	// need to keep that in mind


	// this is output by genconsts.pl
	////////// GENERATED CONSTANTS BEGIN
	HV *stash_Ogre = gv_stashpv("Ogre", TRUE);

	// enum: ParameterType
	newCONSTSUB(stash_Ogre, "PT_BOOL", newSViv(Ogre::PT_BOOL));
	newCONSTSUB(stash_Ogre, "PT_REAL", newSViv(Ogre::PT_REAL));
	newCONSTSUB(stash_Ogre, "PT_INT", newSViv(Ogre::PT_INT));
	newCONSTSUB(stash_Ogre, "PT_UNSIGNED_INT", newSViv(Ogre::PT_UNSIGNED_INT));
	newCONSTSUB(stash_Ogre, "PT_SHORT", newSViv(Ogre::PT_SHORT));
	newCONSTSUB(stash_Ogre, "PT_UNSIGNED_SHORT", newSViv(Ogre::PT_UNSIGNED_SHORT));
	newCONSTSUB(stash_Ogre, "PT_LONG", newSViv(Ogre::PT_LONG));
	newCONSTSUB(stash_Ogre, "PT_UNSIGNED_LONG", newSViv(Ogre::PT_UNSIGNED_LONG));
	newCONSTSUB(stash_Ogre, "PT_STRING", newSViv(Ogre::PT_STRING));
	newCONSTSUB(stash_Ogre, "PT_VECTOR3", newSViv(Ogre::PT_VECTOR3));
	newCONSTSUB(stash_Ogre, "PT_MATRIX3", newSViv(Ogre::PT_MATRIX3));
	newCONSTSUB(stash_Ogre, "PT_MATRIX4", newSViv(Ogre::PT_MATRIX4));
	newCONSTSUB(stash_Ogre, "PT_QUATERNION", newSViv(Ogre::PT_QUATERNION));
	newCONSTSUB(stash_Ogre, "PT_COLOURVALUE", newSViv(Ogre::PT_COLOURVALUE));

	// enum: ShadeOptions
	newCONSTSUB(stash_Ogre, "SO_FLAT", newSViv(Ogre::SO_FLAT));
	newCONSTSUB(stash_Ogre, "SO_GOURAUD", newSViv(Ogre::SO_GOURAUD));
	newCONSTSUB(stash_Ogre, "SO_PHONG", newSViv(Ogre::SO_PHONG));

	// enum: FilterType
	newCONSTSUB(stash_Ogre, "FT_MIN", newSViv(Ogre::FT_MIN));
	newCONSTSUB(stash_Ogre, "FT_MAG", newSViv(Ogre::FT_MAG));
	newCONSTSUB(stash_Ogre, "FT_MIP", newSViv(Ogre::FT_MIP));

	// enum: ProjectionType
	newCONSTSUB(stash_Ogre, "PT_ORTHOGRAPHIC", newSViv(Ogre::PT_ORTHOGRAPHIC));
	newCONSTSUB(stash_Ogre, "PT_PERSPECTIVE", newSViv(Ogre::PT_PERSPECTIVE));

	// enum: PixelFormat
	newCONSTSUB(stash_Ogre, "PF_UNKNOWN", newSViv(Ogre::PF_UNKNOWN));
	newCONSTSUB(stash_Ogre, "PF_L8", newSViv(Ogre::PF_L8));
	newCONSTSUB(stash_Ogre, "PF_BYTE_L", newSViv(Ogre::PF_BYTE_L));
	newCONSTSUB(stash_Ogre, "PF_L16", newSViv(Ogre::PF_L16));
	newCONSTSUB(stash_Ogre, "PF_SHORT_L", newSViv(Ogre::PF_SHORT_L));
	newCONSTSUB(stash_Ogre, "PF_A8", newSViv(Ogre::PF_A8));
	newCONSTSUB(stash_Ogre, "PF_BYTE_A", newSViv(Ogre::PF_BYTE_A));
	newCONSTSUB(stash_Ogre, "PF_A4L4", newSViv(Ogre::PF_A4L4));
	newCONSTSUB(stash_Ogre, "PF_BYTE_LA", newSViv(Ogre::PF_BYTE_LA));
	newCONSTSUB(stash_Ogre, "PF_R5G6B5", newSViv(Ogre::PF_R5G6B5));
	newCONSTSUB(stash_Ogre, "PF_B5G6R5", newSViv(Ogre::PF_B5G6R5));
	newCONSTSUB(stash_Ogre, "PF_R3G3B2", newSViv(Ogre::PF_R3G3B2));
	newCONSTSUB(stash_Ogre, "PF_A4R4G4B4", newSViv(Ogre::PF_A4R4G4B4));
	newCONSTSUB(stash_Ogre, "PF_A1R5G5B5", newSViv(Ogre::PF_A1R5G5B5));
	newCONSTSUB(stash_Ogre, "PF_R8G8B8", newSViv(Ogre::PF_R8G8B8));
	newCONSTSUB(stash_Ogre, "PF_B8G8R8", newSViv(Ogre::PF_B8G8R8));
	newCONSTSUB(stash_Ogre, "PF_A8R8G8B8", newSViv(Ogre::PF_A8R8G8B8));
	newCONSTSUB(stash_Ogre, "PF_A8B8G8R8", newSViv(Ogre::PF_A8B8G8R8));
	newCONSTSUB(stash_Ogre, "PF_B8G8R8A8", newSViv(Ogre::PF_B8G8R8A8));
	newCONSTSUB(stash_Ogre, "PF_R8G8B8A8", newSViv(Ogre::PF_R8G8B8A8));
	newCONSTSUB(stash_Ogre, "PF_X8R8G8B8", newSViv(Ogre::PF_X8R8G8B8));
	newCONSTSUB(stash_Ogre, "PF_X8B8G8R8", newSViv(Ogre::PF_X8B8G8R8));
	newCONSTSUB(stash_Ogre, "PF_BYTE_RGB", newSViv(Ogre::PF_BYTE_RGB));
	newCONSTSUB(stash_Ogre, "PF_BYTE_BGR", newSViv(Ogre::PF_BYTE_BGR));
	newCONSTSUB(stash_Ogre, "PF_BYTE_BGRA", newSViv(Ogre::PF_BYTE_BGRA));
	newCONSTSUB(stash_Ogre, "PF_BYTE_RGBA", newSViv(Ogre::PF_BYTE_RGBA));
	newCONSTSUB(stash_Ogre, "PF_A2R10G10B10", newSViv(Ogre::PF_A2R10G10B10));
	newCONSTSUB(stash_Ogre, "PF_A2B10G10R10", newSViv(Ogre::PF_A2B10G10R10));
	newCONSTSUB(stash_Ogre, "PF_DXT1", newSViv(Ogre::PF_DXT1));
	newCONSTSUB(stash_Ogre, "PF_DXT2", newSViv(Ogre::PF_DXT2));
	newCONSTSUB(stash_Ogre, "PF_DXT3", newSViv(Ogre::PF_DXT3));
	newCONSTSUB(stash_Ogre, "PF_DXT4", newSViv(Ogre::PF_DXT4));
	newCONSTSUB(stash_Ogre, "PF_DXT5", newSViv(Ogre::PF_DXT5));
	newCONSTSUB(stash_Ogre, "PF_FLOAT16_R", newSViv(Ogre::PF_FLOAT16_R));
	newCONSTSUB(stash_Ogre, "PF_FLOAT16_RGB", newSViv(Ogre::PF_FLOAT16_RGB));
	newCONSTSUB(stash_Ogre, "PF_FLOAT16_RGBA", newSViv(Ogre::PF_FLOAT16_RGBA));
	newCONSTSUB(stash_Ogre, "PF_FLOAT32_R", newSViv(Ogre::PF_FLOAT32_R));
	newCONSTSUB(stash_Ogre, "PF_FLOAT32_RGB", newSViv(Ogre::PF_FLOAT32_RGB));
	newCONSTSUB(stash_Ogre, "PF_FLOAT32_RGBA", newSViv(Ogre::PF_FLOAT32_RGBA));
	newCONSTSUB(stash_Ogre, "PF_FLOAT16_GR", newSViv(Ogre::PF_FLOAT16_GR));
	newCONSTSUB(stash_Ogre, "PF_FLOAT32_GR", newSViv(Ogre::PF_FLOAT32_GR));
	newCONSTSUB(stash_Ogre, "PF_DEPTH", newSViv(Ogre::PF_DEPTH));
	newCONSTSUB(stash_Ogre, "PF_SHORT_RGBA", newSViv(Ogre::PF_SHORT_RGBA));
	newCONSTSUB(stash_Ogre, "PF_SHORT_GR", newSViv(Ogre::PF_SHORT_GR));
	newCONSTSUB(stash_Ogre, "PF_SHORT_RGB", newSViv(Ogre::PF_SHORT_RGB));
	newCONSTSUB(stash_Ogre, "PF_COUNT", newSViv(Ogre::PF_COUNT));

	// enum: LayerBlendOperation
	newCONSTSUB(stash_Ogre, "LBO_REPLACE", newSViv(Ogre::LBO_REPLACE));
	newCONSTSUB(stash_Ogre, "LBO_ADD", newSViv(Ogre::LBO_ADD));
	newCONSTSUB(stash_Ogre, "LBO_MODULATE", newSViv(Ogre::LBO_MODULATE));
	newCONSTSUB(stash_Ogre, "LBO_ALPHA_BLEND", newSViv(Ogre::LBO_ALPHA_BLEND));

	// enum: SceneBlendFactor
	newCONSTSUB(stash_Ogre, "SBF_ONE", newSViv(Ogre::SBF_ONE));
	newCONSTSUB(stash_Ogre, "SBF_ZERO", newSViv(Ogre::SBF_ZERO));
	newCONSTSUB(stash_Ogre, "SBF_DEST_COLOUR", newSViv(Ogre::SBF_DEST_COLOUR));
	newCONSTSUB(stash_Ogre, "SBF_SOURCE_COLOUR", newSViv(Ogre::SBF_SOURCE_COLOUR));
	newCONSTSUB(stash_Ogre, "SBF_ONE_MINUS_DEST_COLOUR", newSViv(Ogre::SBF_ONE_MINUS_DEST_COLOUR));
	newCONSTSUB(stash_Ogre, "SBF_ONE_MINUS_SOURCE_COLOUR", newSViv(Ogre::SBF_ONE_MINUS_SOURCE_COLOUR));
	newCONSTSUB(stash_Ogre, "SBF_DEST_ALPHA", newSViv(Ogre::SBF_DEST_ALPHA));
	newCONSTSUB(stash_Ogre, "SBF_SOURCE_ALPHA", newSViv(Ogre::SBF_SOURCE_ALPHA));
	newCONSTSUB(stash_Ogre, "SBF_ONE_MINUS_DEST_ALPHA", newSViv(Ogre::SBF_ONE_MINUS_DEST_ALPHA));
	newCONSTSUB(stash_Ogre, "SBF_ONE_MINUS_SOURCE_ALPHA", newSViv(Ogre::SBF_ONE_MINUS_SOURCE_ALPHA));

	// enum: WaveformType
	newCONSTSUB(stash_Ogre, "WFT_SINE", newSViv(Ogre::WFT_SINE));
	newCONSTSUB(stash_Ogre, "WFT_TRIANGLE", newSViv(Ogre::WFT_TRIANGLE));
	newCONSTSUB(stash_Ogre, "WFT_SQUARE", newSViv(Ogre::WFT_SQUARE));
	newCONSTSUB(stash_Ogre, "WFT_SAWTOOTH", newSViv(Ogre::WFT_SAWTOOTH));
	newCONSTSUB(stash_Ogre, "WFT_INVERSE_SAWTOOTH", newSViv(Ogre::WFT_INVERSE_SAWTOOTH));
	newCONSTSUB(stash_Ogre, "WFT_PWM", newSViv(Ogre::WFT_PWM));

	// enum: TexCoordCalcMethod
	newCONSTSUB(stash_Ogre, "TEXCALC_NONE", newSViv(Ogre::TEXCALC_NONE));
	newCONSTSUB(stash_Ogre, "TEXCALC_ENVIRONMENT_MAP", newSViv(Ogre::TEXCALC_ENVIRONMENT_MAP));
	newCONSTSUB(stash_Ogre, "TEXCALC_ENVIRONMENT_MAP_PLANAR", newSViv(Ogre::TEXCALC_ENVIRONMENT_MAP_PLANAR));
	newCONSTSUB(stash_Ogre, "TEXCALC_ENVIRONMENT_MAP_REFLECTION", newSViv(Ogre::TEXCALC_ENVIRONMENT_MAP_REFLECTION));
	newCONSTSUB(stash_Ogre, "TEXCALC_ENVIRONMENT_MAP_NORMAL", newSViv(Ogre::TEXCALC_ENVIRONMENT_MAP_NORMAL));
	newCONSTSUB(stash_Ogre, "TEXCALC_PROJECTIVE_TEXTURE", newSViv(Ogre::TEXCALC_PROJECTIVE_TEXTURE));

	// enum: FrameBufferType
	newCONSTSUB(stash_Ogre, "FBT_COLOUR", newSViv(Ogre::FBT_COLOUR));
	newCONSTSUB(stash_Ogre, "FBT_DEPTH", newSViv(Ogre::FBT_DEPTH));
	newCONSTSUB(stash_Ogre, "FBT_STENCIL", newSViv(Ogre::FBT_STENCIL));

	// enum: SceneType
	newCONSTSUB(stash_Ogre, "ST_GENERIC", newSViv(Ogre::ST_GENERIC));
	newCONSTSUB(stash_Ogre, "ST_EXTERIOR_CLOSE", newSViv(Ogre::ST_EXTERIOR_CLOSE));
	newCONSTSUB(stash_Ogre, "ST_EXTERIOR_FAR", newSViv(Ogre::ST_EXTERIOR_FAR));
	newCONSTSUB(stash_Ogre, "ST_EXTERIOR_REAL_FAR", newSViv(Ogre::ST_EXTERIOR_REAL_FAR));
	newCONSTSUB(stash_Ogre, "ST_INTERIOR", newSViv(Ogre::ST_INTERIOR));

	// enum: TextureType
	newCONSTSUB(stash_Ogre, "TEX_TYPE_1D", newSViv(Ogre::TEX_TYPE_1D));
	newCONSTSUB(stash_Ogre, "TEX_TYPE_2D", newSViv(Ogre::TEX_TYPE_2D));
	newCONSTSUB(stash_Ogre, "TEX_TYPE_3D", newSViv(Ogre::TEX_TYPE_3D));
	newCONSTSUB(stash_Ogre, "TEX_TYPE_CUBE_MAP", newSViv(Ogre::TEX_TYPE_CUBE_MAP));

	// enum: PolygonMode
	newCONSTSUB(stash_Ogre, "PM_POINTS", newSViv(Ogre::PM_POINTS));
	newCONSTSUB(stash_Ogre, "PM_WIREFRAME", newSViv(Ogre::PM_WIREFRAME));
	newCONSTSUB(stash_Ogre, "PM_SOLID", newSViv(Ogre::PM_SOLID));

	// enum: SceneBlendType
	newCONSTSUB(stash_Ogre, "SBT_TRANSPARENT_ALPHA", newSViv(Ogre::SBT_TRANSPARENT_ALPHA));
	newCONSTSUB(stash_Ogre, "SBT_TRANSPARENT_COLOUR", newSViv(Ogre::SBT_TRANSPARENT_COLOUR));
	newCONSTSUB(stash_Ogre, "SBT_ADD", newSViv(Ogre::SBT_ADD));
	newCONSTSUB(stash_Ogre, "SBT_MODULATE", newSViv(Ogre::SBT_MODULATE));
	newCONSTSUB(stash_Ogre, "SBT_REPLACE", newSViv(Ogre::SBT_REPLACE));

	// enum: FilterOptions
	newCONSTSUB(stash_Ogre, "FO_NONE", newSViv(Ogre::FO_NONE));
	newCONSTSUB(stash_Ogre, "FO_POINT", newSViv(Ogre::FO_POINT));
	newCONSTSUB(stash_Ogre, "FO_LINEAR", newSViv(Ogre::FO_LINEAR));
	newCONSTSUB(stash_Ogre, "FO_ANISOTROPIC", newSViv(Ogre::FO_ANISOTROPIC));

	// enum: StencilOperation
	newCONSTSUB(stash_Ogre, "SOP_KEEP", newSViv(Ogre::SOP_KEEP));
	newCONSTSUB(stash_Ogre, "SOP_ZERO", newSViv(Ogre::SOP_ZERO));
	newCONSTSUB(stash_Ogre, "SOP_REPLACE", newSViv(Ogre::SOP_REPLACE));
	newCONSTSUB(stash_Ogre, "SOP_INCREMENT", newSViv(Ogre::SOP_INCREMENT));
	newCONSTSUB(stash_Ogre, "SOP_DECREMENT", newSViv(Ogre::SOP_DECREMENT));
	newCONSTSUB(stash_Ogre, "SOP_INCREMENT_WRAP", newSViv(Ogre::SOP_INCREMENT_WRAP));
	newCONSTSUB(stash_Ogre, "SOP_DECREMENT_WRAP", newSViv(Ogre::SOP_DECREMENT_WRAP));
	newCONSTSUB(stash_Ogre, "SOP_INVERT", newSViv(Ogre::SOP_INVERT));

	// enum: BillboardType
	newCONSTSUB(stash_Ogre, "BBT_POINT", newSViv(Ogre::BBT_POINT));
	newCONSTSUB(stash_Ogre, "BBT_ORIENTED_COMMON", newSViv(Ogre::BBT_ORIENTED_COMMON));
	newCONSTSUB(stash_Ogre, "BBT_ORIENTED_SELF", newSViv(Ogre::BBT_ORIENTED_SELF));
	newCONSTSUB(stash_Ogre, "BBT_PERPENDICULAR_COMMON", newSViv(Ogre::BBT_PERPENDICULAR_COMMON));
	newCONSTSUB(stash_Ogre, "BBT_PERPENDICULAR_SELF", newSViv(Ogre::BBT_PERPENDICULAR_SELF));

	// enum: LayerBlendType
	newCONSTSUB(stash_Ogre, "LBT_COLOUR", newSViv(Ogre::LBT_COLOUR));
	newCONSTSUB(stash_Ogre, "LBT_ALPHA", newSViv(Ogre::LBT_ALPHA));

	// enum: ImageFlags
	newCONSTSUB(stash_Ogre, "IF_COMPRESSED", newSViv(Ogre::IF_COMPRESSED));
	newCONSTSUB(stash_Ogre, "IF_CUBEMAP", newSViv(Ogre::IF_CUBEMAP));
	newCONSTSUB(stash_Ogre, "IF_3D_TEXTURE", newSViv(Ogre::IF_3D_TEXTURE));

	// enum: LayerBlendOperationEx
	newCONSTSUB(stash_Ogre, "LBX_SOURCE1", newSViv(Ogre::LBX_SOURCE1));
	newCONSTSUB(stash_Ogre, "LBX_SOURCE2", newSViv(Ogre::LBX_SOURCE2));
	newCONSTSUB(stash_Ogre, "LBX_MODULATE", newSViv(Ogre::LBX_MODULATE));
	newCONSTSUB(stash_Ogre, "LBX_MODULATE_X2", newSViv(Ogre::LBX_MODULATE_X2));
	newCONSTSUB(stash_Ogre, "LBX_MODULATE_X4", newSViv(Ogre::LBX_MODULATE_X4));
	newCONSTSUB(stash_Ogre, "LBX_ADD", newSViv(Ogre::LBX_ADD));
	newCONSTSUB(stash_Ogre, "LBX_ADD_SIGNED", newSViv(Ogre::LBX_ADD_SIGNED));
	newCONSTSUB(stash_Ogre, "LBX_ADD_SMOOTH", newSViv(Ogre::LBX_ADD_SMOOTH));
	newCONSTSUB(stash_Ogre, "LBX_SUBTRACT", newSViv(Ogre::LBX_SUBTRACT));
	newCONSTSUB(stash_Ogre, "LBX_BLEND_DIFFUSE_ALPHA", newSViv(Ogre::LBX_BLEND_DIFFUSE_ALPHA));
	newCONSTSUB(stash_Ogre, "LBX_BLEND_TEXTURE_ALPHA", newSViv(Ogre::LBX_BLEND_TEXTURE_ALPHA));
	newCONSTSUB(stash_Ogre, "LBX_BLEND_CURRENT_ALPHA", newSViv(Ogre::LBX_BLEND_CURRENT_ALPHA));
	newCONSTSUB(stash_Ogre, "LBX_BLEND_MANUAL", newSViv(Ogre::LBX_BLEND_MANUAL));
	newCONSTSUB(stash_Ogre, "LBX_DOTPRODUCT", newSViv(Ogre::LBX_DOTPRODUCT));
	newCONSTSUB(stash_Ogre, "LBX_BLEND_DIFFUSE_COLOUR", newSViv(Ogre::LBX_BLEND_DIFFUSE_COLOUR));

	// enum: GuiHorizontalAlignment
	newCONSTSUB(stash_Ogre, "GHA_LEFT", newSViv(Ogre::GHA_LEFT));
	newCONSTSUB(stash_Ogre, "GHA_CENTER", newSViv(Ogre::GHA_CENTER));
	newCONSTSUB(stash_Ogre, "GHA_RIGHT", newSViv(Ogre::GHA_RIGHT));

	// enum: LayerBlendSource
	newCONSTSUB(stash_Ogre, "LBS_CURRENT", newSViv(Ogre::LBS_CURRENT));
	newCONSTSUB(stash_Ogre, "LBS_TEXTURE", newSViv(Ogre::LBS_TEXTURE));
	newCONSTSUB(stash_Ogre, "LBS_DIFFUSE", newSViv(Ogre::LBS_DIFFUSE));
	newCONSTSUB(stash_Ogre, "LBS_SPECULAR", newSViv(Ogre::LBS_SPECULAR));
	newCONSTSUB(stash_Ogre, "LBS_MANUAL", newSViv(Ogre::LBS_MANUAL));

	// enum: GpuConstantType
	newCONSTSUB(stash_Ogre, "GCT_FLOAT1", newSViv(Ogre::GCT_FLOAT1));
	newCONSTSUB(stash_Ogre, "GCT_FLOAT2", newSViv(Ogre::GCT_FLOAT2));
	newCONSTSUB(stash_Ogre, "GCT_FLOAT3", newSViv(Ogre::GCT_FLOAT3));
	newCONSTSUB(stash_Ogre, "GCT_FLOAT4", newSViv(Ogre::GCT_FLOAT4));
	newCONSTSUB(stash_Ogre, "GCT_SAMPLER1D", newSViv(Ogre::GCT_SAMPLER1D));
	newCONSTSUB(stash_Ogre, "GCT_SAMPLER2D", newSViv(Ogre::GCT_SAMPLER2D));
	newCONSTSUB(stash_Ogre, "GCT_SAMPLER3D", newSViv(Ogre::GCT_SAMPLER3D));
	newCONSTSUB(stash_Ogre, "GCT_SAMPLERCUBE", newSViv(Ogre::GCT_SAMPLERCUBE));
	newCONSTSUB(stash_Ogre, "GCT_SAMPLER1DSHADOW", newSViv(Ogre::GCT_SAMPLER1DSHADOW));
	newCONSTSUB(stash_Ogre, "GCT_SAMPLER2DSHADOW", newSViv(Ogre::GCT_SAMPLER2DSHADOW));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_2X2", newSViv(Ogre::GCT_MATRIX_2X2));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_2X3", newSViv(Ogre::GCT_MATRIX_2X3));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_2X4", newSViv(Ogre::GCT_MATRIX_2X4));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_3X2", newSViv(Ogre::GCT_MATRIX_3X2));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_3X3", newSViv(Ogre::GCT_MATRIX_3X3));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_3X4", newSViv(Ogre::GCT_MATRIX_3X4));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_4X2", newSViv(Ogre::GCT_MATRIX_4X2));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_4X3", newSViv(Ogre::GCT_MATRIX_4X3));
	newCONSTSUB(stash_Ogre, "GCT_MATRIX_4X4", newSViv(Ogre::GCT_MATRIX_4X4));
	newCONSTSUB(stash_Ogre, "GCT_INT1", newSViv(Ogre::GCT_INT1));
	newCONSTSUB(stash_Ogre, "GCT_INT2", newSViv(Ogre::GCT_INT2));
	newCONSTSUB(stash_Ogre, "GCT_INT3", newSViv(Ogre::GCT_INT3));
	newCONSTSUB(stash_Ogre, "GCT_INT4", newSViv(Ogre::GCT_INT4));
	newCONSTSUB(stash_Ogre, "GCT_UNKNOWN", newSViv(Ogre::GCT_UNKNOWN));

	// enum: GpuProgramType
	newCONSTSUB(stash_Ogre, "GPT_VERTEX_PROGRAM", newSViv(Ogre::GPT_VERTEX_PROGRAM));
	newCONSTSUB(stash_Ogre, "GPT_FRAGMENT_PROGRAM", newSViv(Ogre::GPT_FRAGMENT_PROGRAM));

	// enum: TextureMipmap
	newCONSTSUB(stash_Ogre, "MIP_UNLIMITED", newSViv(Ogre::MIP_UNLIMITED));
	newCONSTSUB(stash_Ogre, "MIP_DEFAULT", newSViv(Ogre::MIP_DEFAULT));

	// enum: LoggingLevel
	newCONSTSUB(stash_Ogre, "LL_LOW", newSViv(Ogre::LL_LOW));
	newCONSTSUB(stash_Ogre, "LL_NORMAL", newSViv(Ogre::LL_NORMAL));
	newCONSTSUB(stash_Ogre, "LL_BOREME", newSViv(Ogre::LL_BOREME));

	// enum: Capabilities
	newCONSTSUB(stash_Ogre, "RSC_AUTOMIPMAP", newSViv(Ogre::RSC_AUTOMIPMAP));
	newCONSTSUB(stash_Ogre, "RSC_BLENDING", newSViv(Ogre::RSC_BLENDING));
	newCONSTSUB(stash_Ogre, "RSC_ANISOTROPY", newSViv(Ogre::RSC_ANISOTROPY));
	newCONSTSUB(stash_Ogre, "RSC_DOT3", newSViv(Ogre::RSC_DOT3));
	newCONSTSUB(stash_Ogre, "RSC_CUBEMAPPING", newSViv(Ogre::RSC_CUBEMAPPING));
	newCONSTSUB(stash_Ogre, "RSC_HWSTENCIL", newSViv(Ogre::RSC_HWSTENCIL));
	newCONSTSUB(stash_Ogre, "RSC_VBO", newSViv(Ogre::RSC_VBO));
	newCONSTSUB(stash_Ogre, "RSC_VERTEX_PROGRAM", newSViv(Ogre::RSC_VERTEX_PROGRAM));
	newCONSTSUB(stash_Ogre, "RSC_FRAGMENT_PROGRAM", newSViv(Ogre::RSC_FRAGMENT_PROGRAM));
	newCONSTSUB(stash_Ogre, "RSC_TEXTURE_COMPRESSION", newSViv(Ogre::RSC_TEXTURE_COMPRESSION));
	newCONSTSUB(stash_Ogre, "RSC_TEXTURE_COMPRESSION_DXT", newSViv(Ogre::RSC_TEXTURE_COMPRESSION_DXT));
	newCONSTSUB(stash_Ogre, "RSC_TEXTURE_COMPRESSION_VTC", newSViv(Ogre::RSC_TEXTURE_COMPRESSION_VTC));
	newCONSTSUB(stash_Ogre, "RSC_SCISSOR_TEST", newSViv(Ogre::RSC_SCISSOR_TEST));
	newCONSTSUB(stash_Ogre, "RSC_TWO_SIDED_STENCIL", newSViv(Ogre::RSC_TWO_SIDED_STENCIL));
	newCONSTSUB(stash_Ogre, "RSC_STENCIL_WRAP", newSViv(Ogre::RSC_STENCIL_WRAP));
	newCONSTSUB(stash_Ogre, "RSC_HWOCCLUSION", newSViv(Ogre::RSC_HWOCCLUSION));
	newCONSTSUB(stash_Ogre, "RSC_USER_CLIP_PLANES", newSViv(Ogre::RSC_USER_CLIP_PLANES));
	newCONSTSUB(stash_Ogre, "RSC_VERTEX_FORMAT_UBYTE4", newSViv(Ogre::RSC_VERTEX_FORMAT_UBYTE4));
	newCONSTSUB(stash_Ogre, "RSC_INFINITE_FAR_PLANE", newSViv(Ogre::RSC_INFINITE_FAR_PLANE));
	newCONSTSUB(stash_Ogre, "RSC_HWRENDER_TO_TEXTURE", newSViv(Ogre::RSC_HWRENDER_TO_TEXTURE));
	newCONSTSUB(stash_Ogre, "RSC_TEXTURE_FLOAT", newSViv(Ogre::RSC_TEXTURE_FLOAT));
	newCONSTSUB(stash_Ogre, "RSC_NON_POWER_OF_2_TEXTURES", newSViv(Ogre::RSC_NON_POWER_OF_2_TEXTURES));
	newCONSTSUB(stash_Ogre, "RSC_TEXTURE_3D", newSViv(Ogre::RSC_TEXTURE_3D));
	newCONSTSUB(stash_Ogre, "RSC_POINT_SPRITES", newSViv(Ogre::RSC_POINT_SPRITES));
	newCONSTSUB(stash_Ogre, "RSC_POINT_EXTENDED_PARAMETERS", newSViv(Ogre::RSC_POINT_EXTENDED_PARAMETERS));
	newCONSTSUB(stash_Ogre, "RSC_VERTEX_TEXTURE_FETCH", newSViv(Ogre::RSC_VERTEX_TEXTURE_FETCH));
	newCONSTSUB(stash_Ogre, "RSC_MIPMAP_LOD_BIAS", newSViv(Ogre::RSC_MIPMAP_LOD_BIAS));

	// enum: VertexAnimationType
	newCONSTSUB(stash_Ogre, "VAT_NONE", newSViv(Ogre::VAT_NONE));
	newCONSTSUB(stash_Ogre, "VAT_MORPH", newSViv(Ogre::VAT_MORPH));
	newCONSTSUB(stash_Ogre, "VAT_POSE", newSViv(Ogre::VAT_POSE));

	// enum: ShadowTechnique
	newCONSTSUB(stash_Ogre, "SHADOWTYPE_NONE", newSViv(Ogre::SHADOWTYPE_NONE));
	newCONSTSUB(stash_Ogre, "SHADOWDETAILTYPE_ADDITIVE", newSViv(Ogre::SHADOWDETAILTYPE_ADDITIVE));
	newCONSTSUB(stash_Ogre, "SHADOWDETAILTYPE_MODULATIVE", newSViv(Ogre::SHADOWDETAILTYPE_MODULATIVE));
	newCONSTSUB(stash_Ogre, "SHADOWDETAILTYPE_INTEGRATED", newSViv(Ogre::SHADOWDETAILTYPE_INTEGRATED));
	newCONSTSUB(stash_Ogre, "SHADOWDETAILTYPE_STENCIL", newSViv(Ogre::SHADOWDETAILTYPE_STENCIL));
	newCONSTSUB(stash_Ogre, "SHADOWDETAILTYPE_TEXTURE", newSViv(Ogre::SHADOWDETAILTYPE_TEXTURE));
	newCONSTSUB(stash_Ogre, "SHADOWTYPE_STENCIL_MODULATIVE", newSViv(Ogre::SHADOWTYPE_STENCIL_MODULATIVE));
	newCONSTSUB(stash_Ogre, "SHADOWTYPE_STENCIL_ADDITIVE", newSViv(Ogre::SHADOWTYPE_STENCIL_ADDITIVE));
	newCONSTSUB(stash_Ogre, "SHADOWTYPE_TEXTURE_MODULATIVE", newSViv(Ogre::SHADOWTYPE_TEXTURE_MODULATIVE));
	newCONSTSUB(stash_Ogre, "SHADOWTYPE_TEXTURE_ADDITIVE", newSViv(Ogre::SHADOWTYPE_TEXTURE_ADDITIVE));
	newCONSTSUB(stash_Ogre, "SHADOWTYPE_TEXTURE_ADDITIVE_INTEGRATED", newSViv(Ogre::SHADOWTYPE_TEXTURE_ADDITIVE_INTEGRATED));
	newCONSTSUB(stash_Ogre, "SHADOWTYPE_TEXTURE_MODULATIVE_INTEGRATED", newSViv(Ogre::SHADOWTYPE_TEXTURE_MODULATIVE_INTEGRATED));

	// enum: VertexElementType
	newCONSTSUB(stash_Ogre, "VET_FLOAT1", newSViv(Ogre::VET_FLOAT1));
	newCONSTSUB(stash_Ogre, "VET_FLOAT2", newSViv(Ogre::VET_FLOAT2));
	newCONSTSUB(stash_Ogre, "VET_FLOAT3", newSViv(Ogre::VET_FLOAT3));
	newCONSTSUB(stash_Ogre, "VET_FLOAT4", newSViv(Ogre::VET_FLOAT4));
	newCONSTSUB(stash_Ogre, "VET_COLOUR", newSViv(Ogre::VET_COLOUR));
	newCONSTSUB(stash_Ogre, "VET_SHORT1", newSViv(Ogre::VET_SHORT1));
	newCONSTSUB(stash_Ogre, "VET_SHORT2", newSViv(Ogre::VET_SHORT2));
	newCONSTSUB(stash_Ogre, "VET_SHORT3", newSViv(Ogre::VET_SHORT3));
	newCONSTSUB(stash_Ogre, "VET_SHORT4", newSViv(Ogre::VET_SHORT4));
	newCONSTSUB(stash_Ogre, "VET_UBYTE4", newSViv(Ogre::VET_UBYTE4));
	newCONSTSUB(stash_Ogre, "VET_COLOUR_ARGB", newSViv(Ogre::VET_COLOUR_ARGB));
	newCONSTSUB(stash_Ogre, "VET_COLOUR_ABGR", newSViv(Ogre::VET_COLOUR_ABGR));

	// enum: TrackVertexColourEnum
	newCONSTSUB(stash_Ogre, "TVC_NONE", newSViv(Ogre::TVC_NONE));
	newCONSTSUB(stash_Ogre, "TVC_AMBIENT", newSViv(Ogre::TVC_AMBIENT));
	newCONSTSUB(stash_Ogre, "TVC_DIFFUSE", newSViv(Ogre::TVC_DIFFUSE));
	newCONSTSUB(stash_Ogre, "TVC_SPECULAR", newSViv(Ogre::TVC_SPECULAR));
	newCONSTSUB(stash_Ogre, "TVC_EMISSIVE", newSViv(Ogre::TVC_EMISSIVE));

	// enum: GuiVerticalAlignment
	newCONSTSUB(stash_Ogre, "GVA_TOP", newSViv(Ogre::GVA_TOP));
	newCONSTSUB(stash_Ogre, "GVA_CENTER", newSViv(Ogre::GVA_CENTER));
	newCONSTSUB(stash_Ogre, "GVA_BOTTOM", newSViv(Ogre::GVA_BOTTOM));

	// enum: FogMode
	newCONSTSUB(stash_Ogre, "FOG_NONE", newSViv(Ogre::FOG_NONE));
	newCONSTSUB(stash_Ogre, "FOG_EXP", newSViv(Ogre::FOG_EXP));
	newCONSTSUB(stash_Ogre, "FOG_EXP2", newSViv(Ogre::FOG_EXP2));
	newCONSTSUB(stash_Ogre, "FOG_LINEAR", newSViv(Ogre::FOG_LINEAR));

	// enum: BillboardOrigin
	newCONSTSUB(stash_Ogre, "BBO_TOP_LEFT", newSViv(Ogre::BBO_TOP_LEFT));
	newCONSTSUB(stash_Ogre, "BBO_TOP_CENTER", newSViv(Ogre::BBO_TOP_CENTER));
	newCONSTSUB(stash_Ogre, "BBO_TOP_RIGHT", newSViv(Ogre::BBO_TOP_RIGHT));
	newCONSTSUB(stash_Ogre, "BBO_CENTER_LEFT", newSViv(Ogre::BBO_CENTER_LEFT));
	newCONSTSUB(stash_Ogre, "BBO_CENTER", newSViv(Ogre::BBO_CENTER));
	newCONSTSUB(stash_Ogre, "BBO_CENTER_RIGHT", newSViv(Ogre::BBO_CENTER_RIGHT));
	newCONSTSUB(stash_Ogre, "BBO_BOTTOM_LEFT", newSViv(Ogre::BBO_BOTTOM_LEFT));
	newCONSTSUB(stash_Ogre, "BBO_BOTTOM_CENTER", newSViv(Ogre::BBO_BOTTOM_CENTER));
	newCONSTSUB(stash_Ogre, "BBO_BOTTOM_RIGHT", newSViv(Ogre::BBO_BOTTOM_RIGHT));

	// enum: PixelComponentType
	newCONSTSUB(stash_Ogre, "PCT_BYTE", newSViv(Ogre::PCT_BYTE));
	newCONSTSUB(stash_Ogre, "PCT_SHORT", newSViv(Ogre::PCT_SHORT));
	newCONSTSUB(stash_Ogre, "PCT_FLOAT16", newSViv(Ogre::PCT_FLOAT16));
	newCONSTSUB(stash_Ogre, "PCT_FLOAT32", newSViv(Ogre::PCT_FLOAT32));
	newCONSTSUB(stash_Ogre, "PCT_COUNT", newSViv(Ogre::PCT_COUNT));

	// enum: SortMode
	newCONSTSUB(stash_Ogre, "SM_DIRECTION", newSViv(Ogre::SM_DIRECTION));
	newCONSTSUB(stash_Ogre, "SM_DISTANCE", newSViv(Ogre::SM_DISTANCE));

	// enum: SkeletonAnimationBlendMode
	newCONSTSUB(stash_Ogre, "ANIMBLEND_AVERAGE", newSViv(Ogre::ANIMBLEND_AVERAGE));
	newCONSTSUB(stash_Ogre, "ANIMBLEND_CUMULATIVE", newSViv(Ogre::ANIMBLEND_CUMULATIVE));

	// enum: BillboardRotationType
	newCONSTSUB(stash_Ogre, "BBR_VERTEX", newSViv(Ogre::BBR_VERTEX));
	newCONSTSUB(stash_Ogre, "BBR_TEXCOORD", newSViv(Ogre::BBR_TEXCOORD));

	// enum: TextureFilterOptions
	newCONSTSUB(stash_Ogre, "TFO_NONE", newSViv(Ogre::TFO_NONE));
	newCONSTSUB(stash_Ogre, "TFO_BILINEAR", newSViv(Ogre::TFO_BILINEAR));
	newCONSTSUB(stash_Ogre, "TFO_TRILINEAR", newSViv(Ogre::TFO_TRILINEAR));
	newCONSTSUB(stash_Ogre, "TFO_ANISOTROPIC", newSViv(Ogre::TFO_ANISOTROPIC));

	// enum: LogMessageLevel
	newCONSTSUB(stash_Ogre, "LML_TRIVIAL", newSViv(Ogre::LML_TRIVIAL));
	newCONSTSUB(stash_Ogre, "LML_NORMAL", newSViv(Ogre::LML_NORMAL));
	newCONSTSUB(stash_Ogre, "LML_CRITICAL", newSViv(Ogre::LML_CRITICAL));

	// enum: GuiMetricsMode
	newCONSTSUB(stash_Ogre, "GMM_RELATIVE", newSViv(Ogre::GMM_RELATIVE));
	newCONSTSUB(stash_Ogre, "GMM_PIXELS", newSViv(Ogre::GMM_PIXELS));
	newCONSTSUB(stash_Ogre, "GMM_RELATIVE_ASPECT_ADJUSTED", newSViv(Ogre::GMM_RELATIVE_ASPECT_ADJUSTED));

	// enum: TextureUsage
	newCONSTSUB(stash_Ogre, "TU_STATIC", newSViv(Ogre::TU_STATIC));
	newCONSTSUB(stash_Ogre, "TU_DYNAMIC", newSViv(Ogre::TU_DYNAMIC));
	newCONSTSUB(stash_Ogre, "TU_WRITE_ONLY", newSViv(Ogre::TU_WRITE_ONLY));
	newCONSTSUB(stash_Ogre, "TU_STATIC_WRITE_ONLY", newSViv(Ogre::TU_STATIC_WRITE_ONLY));
	newCONSTSUB(stash_Ogre, "TU_DYNAMIC_WRITE_ONLY", newSViv(Ogre::TU_DYNAMIC_WRITE_ONLY));
	newCONSTSUB(stash_Ogre, "TU_DYNAMIC_WRITE_ONLY_DISCARDABLE", newSViv(Ogre::TU_DYNAMIC_WRITE_ONLY_DISCARDABLE));
	newCONSTSUB(stash_Ogre, "TU_AUTOMIPMAP", newSViv(Ogre::TU_AUTOMIPMAP));
	newCONSTSUB(stash_Ogre, "TU_RENDERTARGET", newSViv(Ogre::TU_RENDERTARGET));
	newCONSTSUB(stash_Ogre, "TU_DEFAULT", newSViv(Ogre::TU_DEFAULT));

	// enum: RenderQueueGroupID
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_BACKGROUND", newSViv(Ogre::RENDER_QUEUE_BACKGROUND));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_SKIES_EARLY", newSViv(Ogre::RENDER_QUEUE_SKIES_EARLY));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_1", newSViv(Ogre::RENDER_QUEUE_1));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_2", newSViv(Ogre::RENDER_QUEUE_2));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_WORLD_GEOMETRY_1", newSViv(Ogre::RENDER_QUEUE_WORLD_GEOMETRY_1));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_3", newSViv(Ogre::RENDER_QUEUE_3));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_4", newSViv(Ogre::RENDER_QUEUE_4));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_MAIN", newSViv(Ogre::RENDER_QUEUE_MAIN));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_6", newSViv(Ogre::RENDER_QUEUE_6));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_7", newSViv(Ogre::RENDER_QUEUE_7));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_WORLD_GEOMETRY_2", newSViv(Ogre::RENDER_QUEUE_WORLD_GEOMETRY_2));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_8", newSViv(Ogre::RENDER_QUEUE_8));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_9", newSViv(Ogre::RENDER_QUEUE_9));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_SKIES_LATE", newSViv(Ogre::RENDER_QUEUE_SKIES_LATE));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_OVERLAY", newSViv(Ogre::RENDER_QUEUE_OVERLAY));
	newCONSTSUB(stash_Ogre, "RENDER_QUEUE_MAX", newSViv(Ogre::RENDER_QUEUE_MAX));

	// enum: PixelFormatFlags
	newCONSTSUB(stash_Ogre, "PFF_HASALPHA", newSViv(Ogre::PFF_HASALPHA));
	newCONSTSUB(stash_Ogre, "PFF_COMPRESSED", newSViv(Ogre::PFF_COMPRESSED));
	newCONSTSUB(stash_Ogre, "PFF_FLOAT", newSViv(Ogre::PFF_FLOAT));
	newCONSTSUB(stash_Ogre, "PFF_DEPTH", newSViv(Ogre::PFF_DEPTH));
	newCONSTSUB(stash_Ogre, "PFF_NATIVEENDIAN", newSViv(Ogre::PFF_NATIVEENDIAN));
	newCONSTSUB(stash_Ogre, "PFF_LUMINANCE", newSViv(Ogre::PFF_LUMINANCE));

	// enum: IlluminationStage
	newCONSTSUB(stash_Ogre, "IS_AMBIENT", newSViv(Ogre::IS_AMBIENT));
	newCONSTSUB(stash_Ogre, "IS_PER_LIGHT", newSViv(Ogre::IS_PER_LIGHT));
	newCONSTSUB(stash_Ogre, "IS_DECAL", newSViv(Ogre::IS_DECAL));

	// enum: CullingMode
	newCONSTSUB(stash_Ogre, "CULL_NONE", newSViv(Ogre::CULL_NONE));
	newCONSTSUB(stash_Ogre, "CULL_CLOCKWISE", newSViv(Ogre::CULL_CLOCKWISE));
	newCONSTSUB(stash_Ogre, "CULL_ANTICLOCKWISE", newSViv(Ogre::CULL_ANTICLOCKWISE));

	// enum: VertexElementSemantic
	newCONSTSUB(stash_Ogre, "VES_POSITION", newSViv(Ogre::VES_POSITION));
	newCONSTSUB(stash_Ogre, "VES_BLEND_WEIGHTS", newSViv(Ogre::VES_BLEND_WEIGHTS));
	newCONSTSUB(stash_Ogre, "VES_BLEND_INDICES", newSViv(Ogre::VES_BLEND_INDICES));
	newCONSTSUB(stash_Ogre, "VES_NORMAL", newSViv(Ogre::VES_NORMAL));
	newCONSTSUB(stash_Ogre, "VES_DIFFUSE", newSViv(Ogre::VES_DIFFUSE));
	newCONSTSUB(stash_Ogre, "VES_SPECULAR", newSViv(Ogre::VES_SPECULAR));
	newCONSTSUB(stash_Ogre, "VES_TEXTURE_COORDINATES", newSViv(Ogre::VES_TEXTURE_COORDINATES));
	newCONSTSUB(stash_Ogre, "VES_BINORMAL", newSViv(Ogre::VES_BINORMAL));
	newCONSTSUB(stash_Ogre, "VES_TANGENT", newSViv(Ogre::VES_TANGENT));

	// enum: FrustumPlane
	newCONSTSUB(stash_Ogre, "FRUSTUM_PLANE_NEAR", newSViv(Ogre::FRUSTUM_PLANE_NEAR));
	newCONSTSUB(stash_Ogre, "FRUSTUM_PLANE_FAR", newSViv(Ogre::FRUSTUM_PLANE_FAR));
	newCONSTSUB(stash_Ogre, "FRUSTUM_PLANE_LEFT", newSViv(Ogre::FRUSTUM_PLANE_LEFT));
	newCONSTSUB(stash_Ogre, "FRUSTUM_PLANE_RIGHT", newSViv(Ogre::FRUSTUM_PLANE_RIGHT));
	newCONSTSUB(stash_Ogre, "FRUSTUM_PLANE_TOP", newSViv(Ogre::FRUSTUM_PLANE_TOP));
	newCONSTSUB(stash_Ogre, "FRUSTUM_PLANE_BOTTOM", newSViv(Ogre::FRUSTUM_PLANE_BOTTOM));

	// enum: MaterialScriptSection
	newCONSTSUB(stash_Ogre, "MSS_NONE", newSViv(Ogre::MSS_NONE));
	newCONSTSUB(stash_Ogre, "MSS_MATERIAL", newSViv(Ogre::MSS_MATERIAL));
	newCONSTSUB(stash_Ogre, "MSS_TECHNIQUE", newSViv(Ogre::MSS_TECHNIQUE));
	newCONSTSUB(stash_Ogre, "MSS_PASS", newSViv(Ogre::MSS_PASS));
	newCONSTSUB(stash_Ogre, "MSS_TEXTUREUNIT", newSViv(Ogre::MSS_TEXTUREUNIT));
	newCONSTSUB(stash_Ogre, "MSS_PROGRAM_REF", newSViv(Ogre::MSS_PROGRAM_REF));
	newCONSTSUB(stash_Ogre, "MSS_PROGRAM", newSViv(Ogre::MSS_PROGRAM));
	newCONSTSUB(stash_Ogre, "MSS_DEFAULT_PARAMETERS", newSViv(Ogre::MSS_DEFAULT_PARAMETERS));
	newCONSTSUB(stash_Ogre, "MSS_TEXTURESOURCE", newSViv(Ogre::MSS_TEXTURESOURCE));

	// enum: ShadowRenderableFlags
	newCONSTSUB(stash_Ogre, "SRF_INCLUDE_LIGHT_CAP", newSViv(Ogre::SRF_INCLUDE_LIGHT_CAP));
	newCONSTSUB(stash_Ogre, "SRF_INCLUDE_DARK_CAP", newSViv(Ogre::SRF_INCLUDE_DARK_CAP));
	newCONSTSUB(stash_Ogre, "SRF_EXTRUDE_TO_INFINITY", newSViv(Ogre::SRF_EXTRUDE_TO_INFINITY));

	// enum: ManualCullingMode
	newCONSTSUB(stash_Ogre, "MANUAL_CULL_NONE", newSViv(Ogre::MANUAL_CULL_NONE));
	newCONSTSUB(stash_Ogre, "MANUAL_CULL_BACK", newSViv(Ogre::MANUAL_CULL_BACK));
	newCONSTSUB(stash_Ogre, "MANUAL_CULL_FRONT", newSViv(Ogre::MANUAL_CULL_FRONT));

	// enum: CompareFunction
	newCONSTSUB(stash_Ogre, "CMPF_ALWAYS_FAIL", newSViv(Ogre::CMPF_ALWAYS_FAIL));
	newCONSTSUB(stash_Ogre, "CMPF_ALWAYS_PASS", newSViv(Ogre::CMPF_ALWAYS_PASS));
	newCONSTSUB(stash_Ogre, "CMPF_LESS", newSViv(Ogre::CMPF_LESS));
	newCONSTSUB(stash_Ogre, "CMPF_LESS_EQUAL", newSViv(Ogre::CMPF_LESS_EQUAL));
	newCONSTSUB(stash_Ogre, "CMPF_EQUAL", newSViv(Ogre::CMPF_EQUAL));
	newCONSTSUB(stash_Ogre, "CMPF_NOT_EQUAL", newSViv(Ogre::CMPF_NOT_EQUAL));
	newCONSTSUB(stash_Ogre, "CMPF_GREATER_EQUAL", newSViv(Ogre::CMPF_GREATER_EQUAL));
	newCONSTSUB(stash_Ogre, "CMPF_GREATER", newSViv(Ogre::CMPF_GREATER));

	HV *stash_Ogre__AnimableValue = gv_stashpv("Ogre::AnimableValue", TRUE);

	// enum: ValueType
	newCONSTSUB(stash_Ogre__AnimableValue, "INT", newSViv(Ogre::AnimableValue::INT));
	newCONSTSUB(stash_Ogre__AnimableValue, "REAL", newSViv(Ogre::AnimableValue::REAL));
	newCONSTSUB(stash_Ogre__AnimableValue, "VECTOR2", newSViv(Ogre::AnimableValue::VECTOR2));
	newCONSTSUB(stash_Ogre__AnimableValue, "VECTOR3", newSViv(Ogre::AnimableValue::VECTOR3));
	newCONSTSUB(stash_Ogre__AnimableValue, "VECTOR4", newSViv(Ogre::AnimableValue::VECTOR4));
	newCONSTSUB(stash_Ogre__AnimableValue, "QUATERNION", newSViv(Ogre::AnimableValue::QUATERNION));
	newCONSTSUB(stash_Ogre__AnimableValue, "COLOUR", newSViv(Ogre::AnimableValue::COLOUR));

	HV *stash_Ogre__Animation = gv_stashpv("Ogre::Animation", TRUE);

	// enum: InterpolationMode
	newCONSTSUB(stash_Ogre__Animation, "IM_LINEAR", newSViv(Ogre::Animation::IM_LINEAR));
	newCONSTSUB(stash_Ogre__Animation, "IM_SPLINE", newSViv(Ogre::Animation::IM_SPLINE));

	// enum: RotationInterpolationMode
	newCONSTSUB(stash_Ogre__Animation, "RIM_LINEAR", newSViv(Ogre::Animation::RIM_LINEAR));
	newCONSTSUB(stash_Ogre__Animation, "RIM_SPHERICAL", newSViv(Ogre::Animation::RIM_SPHERICAL));

	HV *stash_Ogre__AxisAlignedBox = gv_stashpv("Ogre::AxisAlignedBox", TRUE);

	// enum: CornerEnum
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "FAR_LEFT_BOTTOM", newSViv(Ogre::AxisAlignedBox::FAR_LEFT_BOTTOM));
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "FAR_LEFT_TOP", newSViv(Ogre::AxisAlignedBox::FAR_LEFT_TOP));
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "FAR_RIGHT_TOP", newSViv(Ogre::AxisAlignedBox::FAR_RIGHT_TOP));
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "FAR_RIGHT_BOTTOM", newSViv(Ogre::AxisAlignedBox::FAR_RIGHT_BOTTOM));
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "NEAR_RIGHT_BOTTOM", newSViv(Ogre::AxisAlignedBox::NEAR_RIGHT_BOTTOM));
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "NEAR_LEFT_BOTTOM", newSViv(Ogre::AxisAlignedBox::NEAR_LEFT_BOTTOM));
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "NEAR_LEFT_TOP", newSViv(Ogre::AxisAlignedBox::NEAR_LEFT_TOP));
	newCONSTSUB(stash_Ogre__AxisAlignedBox, "NEAR_RIGHT_TOP", newSViv(Ogre::AxisAlignedBox::NEAR_RIGHT_TOP));

	HV *stash_Ogre__BillboardChain = gv_stashpv("Ogre::BillboardChain", TRUE);

	// enum: TexCoordDirection
	newCONSTSUB(stash_Ogre__BillboardChain, "TCD_U", newSViv(Ogre::BillboardChain::TCD_U));
	newCONSTSUB(stash_Ogre__BillboardChain, "TCD_V", newSViv(Ogre::BillboardChain::TCD_V));

	HV *stash_Ogre__CompositionPass = gv_stashpv("Ogre::CompositionPass", TRUE);

	// enum: PassType
	newCONSTSUB(stash_Ogre__CompositionPass, "PT_CLEAR", newSViv(Ogre::CompositionPass::PT_CLEAR));
	newCONSTSUB(stash_Ogre__CompositionPass, "PT_STENCIL", newSViv(Ogre::CompositionPass::PT_STENCIL));
	newCONSTSUB(stash_Ogre__CompositionPass, "PT_RENDERSCENE", newSViv(Ogre::CompositionPass::PT_RENDERSCENE));
	newCONSTSUB(stash_Ogre__CompositionPass, "PT_RENDERQUAD", newSViv(Ogre::CompositionPass::PT_RENDERQUAD));

	HV *stash_Ogre__CompositionTargetPass = gv_stashpv("Ogre::CompositionTargetPass", TRUE);

	// enum: InputMode
	newCONSTSUB(stash_Ogre__CompositionTargetPass, "IM_NONE", newSViv(Ogre::CompositionTargetPass::IM_NONE));
	newCONSTSUB(stash_Ogre__CompositionTargetPass, "IM_PREVIOUS", newSViv(Ogre::CompositionTargetPass::IM_PREVIOUS));

	HV *stash_Ogre__Entity = gv_stashpv("Ogre::Entity", TRUE);

	// enum: VertexDataBindChoice
	newCONSTSUB(stash_Ogre__Entity, "BIND_ORIGINAL", newSViv(Ogre::Entity::BIND_ORIGINAL));
	newCONSTSUB(stash_Ogre__Entity, "BIND_SOFTWARE_SKELETAL", newSViv(Ogre::Entity::BIND_SOFTWARE_SKELETAL));
	newCONSTSUB(stash_Ogre__Entity, "BIND_SOFTWARE_MORPH", newSViv(Ogre::Entity::BIND_SOFTWARE_MORPH));
	newCONSTSUB(stash_Ogre__Entity, "BIND_HARDWARE_MORPH", newSViv(Ogre::Entity::BIND_HARDWARE_MORPH));

	HV *stash_Ogre__Exception = gv_stashpv("Ogre::Exception", TRUE);

	// enum: ExceptionCodes
	newCONSTSUB(stash_Ogre__Exception, "ERR_CANNOT_WRITE_TO_FILE", newSViv(Ogre::Exception::ERR_CANNOT_WRITE_TO_FILE));
	newCONSTSUB(stash_Ogre__Exception, "ERR_INVALID_STATE", newSViv(Ogre::Exception::ERR_INVALID_STATE));
	newCONSTSUB(stash_Ogre__Exception, "ERR_INVALIDPARAMS", newSViv(Ogre::Exception::ERR_INVALIDPARAMS));
	newCONSTSUB(stash_Ogre__Exception, "ERR_RENDERINGAPI_ERROR", newSViv(Ogre::Exception::ERR_RENDERINGAPI_ERROR));
	newCONSTSUB(stash_Ogre__Exception, "ERR_DUPLICATE_ITEM", newSViv(Ogre::Exception::ERR_DUPLICATE_ITEM));
	newCONSTSUB(stash_Ogre__Exception, "ERR_ITEM_NOT_FOUND", newSViv(Ogre::Exception::ERR_ITEM_NOT_FOUND));
	newCONSTSUB(stash_Ogre__Exception, "ERR_FILE_NOT_FOUND", newSViv(Ogre::Exception::ERR_FILE_NOT_FOUND));
	newCONSTSUB(stash_Ogre__Exception, "ERR_INTERNAL_ERROR", newSViv(Ogre::Exception::ERR_INTERNAL_ERROR));
	newCONSTSUB(stash_Ogre__Exception, "ERR_RT_ASSERTION_FAILED", newSViv(Ogre::Exception::ERR_RT_ASSERTION_FAILED));
	newCONSTSUB(stash_Ogre__Exception, "ERR_NOT_IMPLEMENTED", newSViv(Ogre::Exception::ERR_NOT_IMPLEMENTED));

	HV *stash_Ogre__GpuProgramParameters = gv_stashpv("Ogre::GpuProgramParameters", TRUE);

	// enum: AutoConstantType
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_WORLD_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_WORLD_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_WORLD_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_WORLD_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TRANSPOSE_WORLD_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_TRANSPOSE_WORLD_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_TRANSPOSE_WORLD_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_TRANSPOSE_WORLD_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_WORLD_MATRIX_ARRAY_3x4", newSViv(Ogre::GpuProgramParameters::ACT_WORLD_MATRIX_ARRAY_3x4));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_WORLD_MATRIX_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_WORLD_MATRIX_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_VIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_VIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_VIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TRANSPOSE_VIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_TRANSPOSE_VIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_TRANSPOSE_VIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_TRANSPOSE_VIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_PROJECTION_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_PROJECTION_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_PROJECTION_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_PROJECTION_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TRANSPOSE_PROJECTION_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_TRANSPOSE_PROJECTION_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_TRANSPOSE_PROJECTION_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_TRANSPOSE_PROJECTION_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_VIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_VIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_VIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TRANSPOSE_VIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_TRANSPOSE_VIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_TRANSPOSE_VIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_TRANSPOSE_VIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_WORLDVIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_WORLDVIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_WORLDVIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_WORLDVIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TRANSPOSE_WORLDVIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_TRANSPOSE_WORLDVIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_TRANSPOSE_WORLDVIEW_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_TRANSPOSE_WORLDVIEW_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_WORLDVIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_WORLDVIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_WORLDVIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_WORLDVIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TRANSPOSE_WORLDVIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_TRANSPOSE_WORLDVIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_TRANSPOSE_WORLDVIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_TRANSPOSE_WORLDVIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_RENDER_TARGET_FLIPPING", newSViv(Ogre::GpuProgramParameters::ACT_RENDER_TARGET_FLIPPING));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_FOG_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_FOG_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_FOG_PARAMS", newSViv(Ogre::GpuProgramParameters::ACT_FOG_PARAMS));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SURFACE_AMBIENT_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_SURFACE_AMBIENT_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SURFACE_DIFFUSE_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_SURFACE_DIFFUSE_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SURFACE_SPECULAR_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_SURFACE_SPECULAR_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SURFACE_EMISSIVE_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_SURFACE_EMISSIVE_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SURFACE_SHININESS", newSViv(Ogre::GpuProgramParameters::ACT_SURFACE_SHININESS));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_AMBIENT_LIGHT_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_AMBIENT_LIGHT_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIFFUSE_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIFFUSE_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_SPECULAR_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_SPECULAR_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_ATTENUATION", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_ATTENUATION));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SPOTLIGHT_PARAMS", newSViv(Ogre::GpuProgramParameters::ACT_SPOTLIGHT_PARAMS));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POSITION", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POSITION));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POSITION_OBJECT_SPACE", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POSITION_OBJECT_SPACE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POSITION_VIEW_SPACE", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POSITION_VIEW_SPACE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIRECTION", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIRECTION));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIRECTION_OBJECT_SPACE", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIRECTION_OBJECT_SPACE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIRECTION_VIEW_SPACE", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIRECTION_VIEW_SPACE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DISTANCE_OBJECT_SPACE", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DISTANCE_OBJECT_SPACE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POWER_SCALE", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POWER_SCALE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIFFUSE_COLOUR_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIFFUSE_COLOUR_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_SPECULAR_COLOUR_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_SPECULAR_COLOUR_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_ATTENUATION_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_ATTENUATION_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POSITION_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POSITION_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POSITION_OBJECT_SPACE_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POSITION_OBJECT_SPACE_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POSITION_VIEW_SPACE_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POSITION_VIEW_SPACE_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIRECTION_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIRECTION_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIRECTION_OBJECT_SPACE_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIRECTION_OBJECT_SPACE_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DIRECTION_VIEW_SPACE_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DIRECTION_VIEW_SPACE_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_DISTANCE_OBJECT_SPACE_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_DISTANCE_OBJECT_SPACE_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_LIGHT_POWER_SCALE_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_LIGHT_POWER_SCALE_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SPOTLIGHT_PARAMS_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_SPOTLIGHT_PARAMS_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_DERIVED_AMBIENT_LIGHT_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_DERIVED_AMBIENT_LIGHT_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_DERIVED_SCENE_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_DERIVED_SCENE_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_DERIVED_LIGHT_DIFFUSE_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_DERIVED_LIGHT_DIFFUSE_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_DERIVED_LIGHT_SPECULAR_COLOUR", newSViv(Ogre::GpuProgramParameters::ACT_DERIVED_LIGHT_SPECULAR_COLOUR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_DERIVED_LIGHT_DIFFUSE_COLOUR_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_DERIVED_LIGHT_DIFFUSE_COLOUR_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_DERIVED_LIGHT_SPECULAR_COLOUR_ARRAY", newSViv(Ogre::GpuProgramParameters::ACT_DERIVED_LIGHT_SPECULAR_COLOUR_ARRAY));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SHADOW_EXTRUSION_DISTANCE", newSViv(Ogre::GpuProgramParameters::ACT_SHADOW_EXTRUSION_DISTANCE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_CAMERA_POSITION", newSViv(Ogre::GpuProgramParameters::ACT_CAMERA_POSITION));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_CAMERA_POSITION_OBJECT_SPACE", newSViv(Ogre::GpuProgramParameters::ACT_CAMERA_POSITION_OBJECT_SPACE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TEXTURE_VIEWPROJ_MATRIX", newSViv(Ogre::GpuProgramParameters::ACT_TEXTURE_VIEWPROJ_MATRIX));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_CUSTOM", newSViv(Ogre::GpuProgramParameters::ACT_CUSTOM));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TIME", newSViv(Ogre::GpuProgramParameters::ACT_TIME));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TIME_0_X", newSViv(Ogre::GpuProgramParameters::ACT_TIME_0_X));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_COSTIME_0_X", newSViv(Ogre::GpuProgramParameters::ACT_COSTIME_0_X));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SINTIME_0_X", newSViv(Ogre::GpuProgramParameters::ACT_SINTIME_0_X));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TANTIME_0_X", newSViv(Ogre::GpuProgramParameters::ACT_TANTIME_0_X));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TIME_0_X_PACKED", newSViv(Ogre::GpuProgramParameters::ACT_TIME_0_X_PACKED));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TIME_0_1", newSViv(Ogre::GpuProgramParameters::ACT_TIME_0_1));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_COSTIME_0_1", newSViv(Ogre::GpuProgramParameters::ACT_COSTIME_0_1));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SINTIME_0_1", newSViv(Ogre::GpuProgramParameters::ACT_SINTIME_0_1));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TANTIME_0_1", newSViv(Ogre::GpuProgramParameters::ACT_TANTIME_0_1));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TIME_0_1_PACKED", newSViv(Ogre::GpuProgramParameters::ACT_TIME_0_1_PACKED));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TIME_0_2PI", newSViv(Ogre::GpuProgramParameters::ACT_TIME_0_2PI));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_COSTIME_0_2PI", newSViv(Ogre::GpuProgramParameters::ACT_COSTIME_0_2PI));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SINTIME_0_2PI", newSViv(Ogre::GpuProgramParameters::ACT_SINTIME_0_2PI));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TANTIME_0_2PI", newSViv(Ogre::GpuProgramParameters::ACT_TANTIME_0_2PI));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TIME_0_2PI_PACKED", newSViv(Ogre::GpuProgramParameters::ACT_TIME_0_2PI_PACKED));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_FRAME_TIME", newSViv(Ogre::GpuProgramParameters::ACT_FRAME_TIME));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_FPS", newSViv(Ogre::GpuProgramParameters::ACT_FPS));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEWPORT_WIDTH", newSViv(Ogre::GpuProgramParameters::ACT_VIEWPORT_WIDTH));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEWPORT_HEIGHT", newSViv(Ogre::GpuProgramParameters::ACT_VIEWPORT_HEIGHT));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_VIEWPORT_WIDTH", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_VIEWPORT_WIDTH));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_VIEWPORT_HEIGHT", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_VIEWPORT_HEIGHT));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEWPORT_SIZE", newSViv(Ogre::GpuProgramParameters::ACT_VIEWPORT_SIZE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEW_DIRECTION", newSViv(Ogre::GpuProgramParameters::ACT_VIEW_DIRECTION));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEW_SIDE_VECTOR", newSViv(Ogre::GpuProgramParameters::ACT_VIEW_SIDE_VECTOR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_VIEW_UP_VECTOR", newSViv(Ogre::GpuProgramParameters::ACT_VIEW_UP_VECTOR));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_FOV", newSViv(Ogre::GpuProgramParameters::ACT_FOV));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_NEAR_CLIP_DISTANCE", newSViv(Ogre::GpuProgramParameters::ACT_NEAR_CLIP_DISTANCE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_FAR_CLIP_DISTANCE", newSViv(Ogre::GpuProgramParameters::ACT_FAR_CLIP_DISTANCE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_PASS_NUMBER", newSViv(Ogre::GpuProgramParameters::ACT_PASS_NUMBER));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_PASS_ITERATION_NUMBER", newSViv(Ogre::GpuProgramParameters::ACT_PASS_ITERATION_NUMBER));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_ANIMATION_PARAMETRIC", newSViv(Ogre::GpuProgramParameters::ACT_ANIMATION_PARAMETRIC));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TEXEL_OFFSETS", newSViv(Ogre::GpuProgramParameters::ACT_TEXEL_OFFSETS));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SCENE_DEPTH_RANGE", newSViv(Ogre::GpuProgramParameters::ACT_SCENE_DEPTH_RANGE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_SHADOW_SCENE_DEPTH_RANGE", newSViv(Ogre::GpuProgramParameters::ACT_SHADOW_SCENE_DEPTH_RANGE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_TEXTURE_SIZE", newSViv(Ogre::GpuProgramParameters::ACT_TEXTURE_SIZE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_INVERSE_TEXTURE_SIZE", newSViv(Ogre::GpuProgramParameters::ACT_INVERSE_TEXTURE_SIZE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACT_PACKED_TEXTURE_SIZE", newSViv(Ogre::GpuProgramParameters::ACT_PACKED_TEXTURE_SIZE));

	// enum: ElementType
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ET_INT", newSViv(Ogre::GpuProgramParameters::ET_INT));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ET_REAL", newSViv(Ogre::GpuProgramParameters::ET_REAL));

	// enum: ACDataType
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACDT_NONE", newSViv(Ogre::GpuProgramParameters::ACDT_NONE));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACDT_INT", newSViv(Ogre::GpuProgramParameters::ACDT_INT));
	newCONSTSUB(stash_Ogre__GpuProgramParameters, "ACDT_REAL", newSViv(Ogre::GpuProgramParameters::ACDT_REAL));

	HV *stash_Ogre__HardwareBuffer = gv_stashpv("Ogre::HardwareBuffer", TRUE);

	// enum: LockOptions
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBL_NORMAL", newSViv(Ogre::HardwareBuffer::HBL_NORMAL));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBL_DISCARD", newSViv(Ogre::HardwareBuffer::HBL_DISCARD));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBL_READ_ONLY", newSViv(Ogre::HardwareBuffer::HBL_READ_ONLY));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBL_NO_OVERWRITE", newSViv(Ogre::HardwareBuffer::HBL_NO_OVERWRITE));

	// enum: Usage
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBU_STATIC", newSViv(Ogre::HardwareBuffer::HBU_STATIC));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBU_DYNAMIC", newSViv(Ogre::HardwareBuffer::HBU_DYNAMIC));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBU_WRITE_ONLY", newSViv(Ogre::HardwareBuffer::HBU_WRITE_ONLY));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBU_DISCARDABLE", newSViv(Ogre::HardwareBuffer::HBU_DISCARDABLE));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBU_STATIC_WRITE_ONLY", newSViv(Ogre::HardwareBuffer::HBU_STATIC_WRITE_ONLY));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBU_DYNAMIC_WRITE_ONLY", newSViv(Ogre::HardwareBuffer::HBU_DYNAMIC_WRITE_ONLY));
	newCONSTSUB(stash_Ogre__HardwareBuffer, "HBU_DYNAMIC_WRITE_ONLY_DISCARDABLE", newSViv(Ogre::HardwareBuffer::HBU_DYNAMIC_WRITE_ONLY_DISCARDABLE));

	HV *stash_Ogre__HardwareBufferManager = gv_stashpv("Ogre::HardwareBufferManager", TRUE);

	// enum: BufferLicenseType
	newCONSTSUB(stash_Ogre__HardwareBufferManager, "BLT_MANUAL_RELEASE", newSViv(Ogre::HardwareBufferManager::BLT_MANUAL_RELEASE));
	newCONSTSUB(stash_Ogre__HardwareBufferManager, "BLT_AUTOMATIC_RELEASE", newSViv(Ogre::HardwareBufferManager::BLT_AUTOMATIC_RELEASE));

	HV *stash_Ogre__HardwareIndexBuffer = gv_stashpv("Ogre::HardwareIndexBuffer", TRUE);

	// enum: IndexType
	newCONSTSUB(stash_Ogre__HardwareIndexBuffer, "IT_16BIT", newSViv(Ogre::HardwareIndexBuffer::IT_16BIT));
	newCONSTSUB(stash_Ogre__HardwareIndexBuffer, "IT_32BIT", newSViv(Ogre::HardwareIndexBuffer::IT_32BIT));

	HV *stash_Ogre__Image = gv_stashpv("Ogre::Image", TRUE);

	// enum: Filter
	newCONSTSUB(stash_Ogre__Image, "FILTER_NEAREST", newSViv(Ogre::Image::FILTER_NEAREST));
	newCONSTSUB(stash_Ogre__Image, "FILTER_LINEAR", newSViv(Ogre::Image::FILTER_LINEAR));
	newCONSTSUB(stash_Ogre__Image, "FILTER_BILINEAR", newSViv(Ogre::Image::FILTER_BILINEAR));
	newCONSTSUB(stash_Ogre__Image, "FILTER_BOX", newSViv(Ogre::Image::FILTER_BOX));
	newCONSTSUB(stash_Ogre__Image, "FILTER_TRIANGLE", newSViv(Ogre::Image::FILTER_TRIANGLE));
	newCONSTSUB(stash_Ogre__Image, "FILTER_BICUBIC", newSViv(Ogre::Image::FILTER_BICUBIC));

	HV *stash_Ogre__InstancedGeometry__InstancedObject = gv_stashpv("Ogre::InstancedGeometry::InstancedObject", TRUE);

	// enum: TransformSpace
	newCONSTSUB(stash_Ogre__InstancedGeometry__InstancedObject, "TS_LOCAL", newSViv(Ogre::InstancedGeometry::InstancedObject::TS_LOCAL));
	newCONSTSUB(stash_Ogre__InstancedGeometry__InstancedObject, "TS_PARENT", newSViv(Ogre::InstancedGeometry::InstancedObject::TS_PARENT));
	newCONSTSUB(stash_Ogre__InstancedGeometry__InstancedObject, "TS_WORLD", newSViv(Ogre::InstancedGeometry::InstancedObject::TS_WORLD));

	HV *stash_Ogre__Light = gv_stashpv("Ogre::Light", TRUE);

	// enum: LightTypes
	newCONSTSUB(stash_Ogre__Light, "LT_POINT", newSViv(Ogre::Light::LT_POINT));
	newCONSTSUB(stash_Ogre__Light, "LT_DIRECTIONAL", newSViv(Ogre::Light::LT_DIRECTIONAL));
	newCONSTSUB(stash_Ogre__Light, "LT_SPOTLIGHT", newSViv(Ogre::Light::LT_SPOTLIGHT));

	HV *stash_Ogre__Math = gv_stashpv("Ogre::Math", TRUE);

	// enum: AngleUnit
	newCONSTSUB(stash_Ogre__Math, "AU_DEGREE", newSViv(Ogre::Math::AU_DEGREE));
	newCONSTSUB(stash_Ogre__Math, "AU_RADIAN", newSViv(Ogre::Math::AU_RADIAN));

	HV *stash_Ogre__Node = gv_stashpv("Ogre::Node", TRUE);

	// enum: TransformSpace
	newCONSTSUB(stash_Ogre__Node, "TS_LOCAL", newSViv(Ogre::Node::TS_LOCAL));
	newCONSTSUB(stash_Ogre__Node, "TS_PARENT", newSViv(Ogre::Node::TS_PARENT));
	newCONSTSUB(stash_Ogre__Node, "TS_WORLD", newSViv(Ogre::Node::TS_WORLD));

	HV *stash_Ogre__Particle = gv_stashpv("Ogre::Particle", TRUE);

	// enum: ParticleType
	newCONSTSUB(stash_Ogre__Particle, "Visual", newSViv(Ogre::Particle::Visual));
	newCONSTSUB(stash_Ogre__Particle, "Emitter", newSViv(Ogre::Particle::Emitter));

	HV *stash_Ogre__Pass = gv_stashpv("Ogre::Pass", TRUE);

	// enum: BuiltinHashFunction
	newCONSTSUB(stash_Ogre__Pass, "MIN_TEXTURE_CHANGE", newSViv(Ogre::Pass::MIN_TEXTURE_CHANGE));
	newCONSTSUB(stash_Ogre__Pass, "MIN_GPU_PROGRAM_CHANGE", newSViv(Ogre::Pass::MIN_GPU_PROGRAM_CHANGE));

	HV *stash_Ogre__PatchSurface = gv_stashpv("Ogre::PatchSurface", TRUE);

	// enum: ._100
	newCONSTSUB(stash_Ogre__PatchSurface, "AUTO_LEVEL", newSViv(Ogre::PatchSurface::AUTO_LEVEL));

	// enum: VisibleSide
	newCONSTSUB(stash_Ogre__PatchSurface, "VS_FRONT", newSViv(Ogre::PatchSurface::VS_FRONT));
	newCONSTSUB(stash_Ogre__PatchSurface, "VS_BACK", newSViv(Ogre::PatchSurface::VS_BACK));
	newCONSTSUB(stash_Ogre__PatchSurface, "VS_BOTH", newSViv(Ogre::PatchSurface::VS_BOTH));

	// enum: PatchSurfaceType
	newCONSTSUB(stash_Ogre__PatchSurface, "PST_BEZIER", newSViv(Ogre::PatchSurface::PST_BEZIER));

	HV *stash_Ogre__Plane = gv_stashpv("Ogre::Plane", TRUE);

	// enum: Side
	newCONSTSUB(stash_Ogre__Plane, "NO_SIDE", newSViv(Ogre::Plane::NO_SIDE));
	newCONSTSUB(stash_Ogre__Plane, "POSITIVE_SIDE", newSViv(Ogre::Plane::POSITIVE_SIDE));
	newCONSTSUB(stash_Ogre__Plane, "NEGATIVE_SIDE", newSViv(Ogre::Plane::NEGATIVE_SIDE));
	newCONSTSUB(stash_Ogre__Plane, "BOTH_SIDE", newSViv(Ogre::Plane::BOTH_SIDE));

	HV *stash_Ogre__QueuedRenderableCollection = gv_stashpv("Ogre::QueuedRenderableCollection", TRUE);

	// enum: OrganisationMode
	newCONSTSUB(stash_Ogre__QueuedRenderableCollection, "OM_PASS_GROUP", newSViv(Ogre::QueuedRenderableCollection::OM_PASS_GROUP));
	newCONSTSUB(stash_Ogre__QueuedRenderableCollection, "OM_SORT_DESCENDING", newSViv(Ogre::QueuedRenderableCollection::OM_SORT_DESCENDING));
	newCONSTSUB(stash_Ogre__QueuedRenderableCollection, "OM_SORT_ASCENDING", newSViv(Ogre::QueuedRenderableCollection::OM_SORT_ASCENDING));

	HV *stash_Ogre__RenderOperation = gv_stashpv("Ogre::RenderOperation", TRUE);

	// enum: OperationType
	newCONSTSUB(stash_Ogre__RenderOperation, "OT_POINT_LIST", newSViv(Ogre::RenderOperation::OT_POINT_LIST));
	newCONSTSUB(stash_Ogre__RenderOperation, "OT_LINE_LIST", newSViv(Ogre::RenderOperation::OT_LINE_LIST));
	newCONSTSUB(stash_Ogre__RenderOperation, "OT_LINE_STRIP", newSViv(Ogre::RenderOperation::OT_LINE_STRIP));
	newCONSTSUB(stash_Ogre__RenderOperation, "OT_TRIANGLE_LIST", newSViv(Ogre::RenderOperation::OT_TRIANGLE_LIST));
	newCONSTSUB(stash_Ogre__RenderOperation, "OT_TRIANGLE_STRIP", newSViv(Ogre::RenderOperation::OT_TRIANGLE_STRIP));
	newCONSTSUB(stash_Ogre__RenderOperation, "OT_TRIANGLE_FAN", newSViv(Ogre::RenderOperation::OT_TRIANGLE_FAN));

	HV *stash_Ogre__RenderTarget = gv_stashpv("Ogre::RenderTarget", TRUE);

	// enum: StatFlags
	newCONSTSUB(stash_Ogre__RenderTarget, "SF_NONE", newSViv(Ogre::RenderTarget::SF_NONE));
	newCONSTSUB(stash_Ogre__RenderTarget, "SF_FPS", newSViv(Ogre::RenderTarget::SF_FPS));
	newCONSTSUB(stash_Ogre__RenderTarget, "SF_AVG_FPS", newSViv(Ogre::RenderTarget::SF_AVG_FPS));
	newCONSTSUB(stash_Ogre__RenderTarget, "SF_BEST_FPS", newSViv(Ogre::RenderTarget::SF_BEST_FPS));
	newCONSTSUB(stash_Ogre__RenderTarget, "SF_WORST_FPS", newSViv(Ogre::RenderTarget::SF_WORST_FPS));
	newCONSTSUB(stash_Ogre__RenderTarget, "SF_TRIANGLE_COUNT", newSViv(Ogre::RenderTarget::SF_TRIANGLE_COUNT));
	newCONSTSUB(stash_Ogre__RenderTarget, "SF_ALL", newSViv(Ogre::RenderTarget::SF_ALL));

	HV *stash_Ogre__Resource = gv_stashpv("Ogre::Resource", TRUE);

	// enum: LoadingState
	newCONSTSUB(stash_Ogre__Resource, "LOADSTATE_UNLOADED", newSViv(Ogre::Resource::LOADSTATE_UNLOADED));
	newCONSTSUB(stash_Ogre__Resource, "LOADSTATE_LOADING", newSViv(Ogre::Resource::LOADSTATE_LOADING));
	newCONSTSUB(stash_Ogre__Resource, "LOADSTATE_LOADED", newSViv(Ogre::Resource::LOADSTATE_LOADED));
	newCONSTSUB(stash_Ogre__Resource, "LOADSTATE_UNLOADING", newSViv(Ogre::Resource::LOADSTATE_UNLOADING));

	HV *stash_Ogre__SceneManager = gv_stashpv("Ogre::SceneManager", TRUE);

	// enum: PrefabType
	newCONSTSUB(stash_Ogre__SceneManager, "PT_PLANE", newSViv(Ogre::SceneManager::PT_PLANE));
	newCONSTSUB(stash_Ogre__SceneManager, "PT_CUBE", newSViv(Ogre::SceneManager::PT_CUBE));
	newCONSTSUB(stash_Ogre__SceneManager, "PT_SPHERE", newSViv(Ogre::SceneManager::PT_SPHERE));

	// enum: SpecialCaseRenderQueueMode
	newCONSTSUB(stash_Ogre__SceneManager, "SCRQM_INCLUDE", newSViv(Ogre::SceneManager::SCRQM_INCLUDE));
	newCONSTSUB(stash_Ogre__SceneManager, "SCRQM_EXCLUDE", newSViv(Ogre::SceneManager::SCRQM_EXCLUDE));

	// enum: IlluminationRenderStage
	newCONSTSUB(stash_Ogre__SceneManager, "IRS_NONE", newSViv(Ogre::SceneManager::IRS_NONE));
	newCONSTSUB(stash_Ogre__SceneManager, "IRS_RENDER_TO_TEXTURE", newSViv(Ogre::SceneManager::IRS_RENDER_TO_TEXTURE));
	newCONSTSUB(stash_Ogre__SceneManager, "IRS_RENDER_RECEIVER_PASS", newSViv(Ogre::SceneManager::IRS_RENDER_RECEIVER_PASS));

	HV *stash_Ogre__SceneQuery = gv_stashpv("Ogre::SceneQuery", TRUE);

	// enum: WorldFragmentType
	newCONSTSUB(stash_Ogre__SceneQuery, "WFT_NONE", newSViv(Ogre::SceneQuery::WFT_NONE));
	newCONSTSUB(stash_Ogre__SceneQuery, "WFT_PLANE_BOUNDED_REGION", newSViv(Ogre::SceneQuery::WFT_PLANE_BOUNDED_REGION));
	newCONSTSUB(stash_Ogre__SceneQuery, "WFT_SINGLE_INTERSECTION", newSViv(Ogre::SceneQuery::WFT_SINGLE_INTERSECTION));
	newCONSTSUB(stash_Ogre__SceneQuery, "WFT_CUSTOM_GEOMETRY", newSViv(Ogre::SceneQuery::WFT_CUSTOM_GEOMETRY));
	newCONSTSUB(stash_Ogre__SceneQuery, "WFT_RENDER_OPERATION", newSViv(Ogre::SceneQuery::WFT_RENDER_OPERATION));

	HV *stash_Ogre__Serializer = gv_stashpv("Ogre::Serializer", TRUE);

	// enum: Endian
	newCONSTSUB(stash_Ogre__Serializer, "ENDIAN_NATIVE", newSViv(Ogre::Serializer::ENDIAN_NATIVE));
	newCONSTSUB(stash_Ogre__Serializer, "ENDIAN_BIG", newSViv(Ogre::Serializer::ENDIAN_BIG));
	newCONSTSUB(stash_Ogre__Serializer, "ENDIAN_LITTLE", newSViv(Ogre::Serializer::ENDIAN_LITTLE));

	HV *stash_Ogre__TextureUnitState = gv_stashpv("Ogre::TextureUnitState", TRUE);

	// enum: EnvMapType
	newCONSTSUB(stash_Ogre__TextureUnitState, "ENV_PLANAR", newSViv(Ogre::TextureUnitState::ENV_PLANAR));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ENV_CURVED", newSViv(Ogre::TextureUnitState::ENV_CURVED));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ENV_REFLECTION", newSViv(Ogre::TextureUnitState::ENV_REFLECTION));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ENV_NORMAL", newSViv(Ogre::TextureUnitState::ENV_NORMAL));

	// enum: ContentType
	newCONSTSUB(stash_Ogre__TextureUnitState, "CONTENT_NAMED", newSViv(Ogre::TextureUnitState::CONTENT_NAMED));
	newCONSTSUB(stash_Ogre__TextureUnitState, "CONTENT_SHADOW", newSViv(Ogre::TextureUnitState::CONTENT_SHADOW));

	// enum: TextureCubeFace
	newCONSTSUB(stash_Ogre__TextureUnitState, "CUBE_FRONT", newSViv(Ogre::TextureUnitState::CUBE_FRONT));
	newCONSTSUB(stash_Ogre__TextureUnitState, "CUBE_BACK", newSViv(Ogre::TextureUnitState::CUBE_BACK));
	newCONSTSUB(stash_Ogre__TextureUnitState, "CUBE_LEFT", newSViv(Ogre::TextureUnitState::CUBE_LEFT));
	newCONSTSUB(stash_Ogre__TextureUnitState, "CUBE_RIGHT", newSViv(Ogre::TextureUnitState::CUBE_RIGHT));
	newCONSTSUB(stash_Ogre__TextureUnitState, "CUBE_UP", newSViv(Ogre::TextureUnitState::CUBE_UP));
	newCONSTSUB(stash_Ogre__TextureUnitState, "CUBE_DOWN", newSViv(Ogre::TextureUnitState::CUBE_DOWN));

	// enum: TextureAddressingMode
	newCONSTSUB(stash_Ogre__TextureUnitState, "TAM_WRAP", newSViv(Ogre::TextureUnitState::TAM_WRAP));
	newCONSTSUB(stash_Ogre__TextureUnitState, "TAM_MIRROR", newSViv(Ogre::TextureUnitState::TAM_MIRROR));
	newCONSTSUB(stash_Ogre__TextureUnitState, "TAM_CLAMP", newSViv(Ogre::TextureUnitState::TAM_CLAMP));
	newCONSTSUB(stash_Ogre__TextureUnitState, "TAM_BORDER", newSViv(Ogre::TextureUnitState::TAM_BORDER));

	// enum: TextureEffectType
	newCONSTSUB(stash_Ogre__TextureUnitState, "ET_ENVIRONMENT_MAP", newSViv(Ogre::TextureUnitState::ET_ENVIRONMENT_MAP));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ET_PROJECTIVE_TEXTURE", newSViv(Ogre::TextureUnitState::ET_PROJECTIVE_TEXTURE));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ET_UVSCROLL", newSViv(Ogre::TextureUnitState::ET_UVSCROLL));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ET_USCROLL", newSViv(Ogre::TextureUnitState::ET_USCROLL));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ET_VSCROLL", newSViv(Ogre::TextureUnitState::ET_VSCROLL));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ET_ROTATE", newSViv(Ogre::TextureUnitState::ET_ROTATE));
	newCONSTSUB(stash_Ogre__TextureUnitState, "ET_TRANSFORM", newSViv(Ogre::TextureUnitState::ET_TRANSFORM));

	// enum: BindingType
	newCONSTSUB(stash_Ogre__TextureUnitState, "BT_FRAGMENT", newSViv(Ogre::TextureUnitState::BT_FRAGMENT));
	newCONSTSUB(stash_Ogre__TextureUnitState, "BT_VERTEX", newSViv(Ogre::TextureUnitState::BT_VERTEX));

	// enum: TextureTransformType
	newCONSTSUB(stash_Ogre__TextureUnitState, "TT_TRANSLATE_U", newSViv(Ogre::TextureUnitState::TT_TRANSLATE_U));
	newCONSTSUB(stash_Ogre__TextureUnitState, "TT_TRANSLATE_V", newSViv(Ogre::TextureUnitState::TT_TRANSLATE_V));
	newCONSTSUB(stash_Ogre__TextureUnitState, "TT_SCALE_U", newSViv(Ogre::TextureUnitState::TT_SCALE_U));
	newCONSTSUB(stash_Ogre__TextureUnitState, "TT_SCALE_V", newSViv(Ogre::TextureUnitState::TT_SCALE_V));
	newCONSTSUB(stash_Ogre__TextureUnitState, "TT_ROTATE", newSViv(Ogre::TextureUnitState::TT_ROTATE));

	HV *stash_Ogre__VertexAnimationTrack = gv_stashpv("Ogre::VertexAnimationTrack", TRUE);

	// enum: TargetMode
	newCONSTSUB(stash_Ogre__VertexAnimationTrack, "TM_SOFTWARE", newSViv(Ogre::VertexAnimationTrack::TM_SOFTWARE));
	newCONSTSUB(stash_Ogre__VertexAnimationTrack, "TM_HARDWARE", newSViv(Ogre::VertexAnimationTrack::TM_HARDWARE));

	HV *stash_Ogre__VertexCacheProfiler = gv_stashpv("Ogre::VertexCacheProfiler", TRUE);

	// enum: CacheType
	newCONSTSUB(stash_Ogre__VertexCacheProfiler, "FIFO", newSViv(Ogre::VertexCacheProfiler::FIFO));
	newCONSTSUB(stash_Ogre__VertexCacheProfiler, "LRU", newSViv(Ogre::VertexCacheProfiler::LRU));

	////////// GENERATED CONSTANTS END


        // special additions....
        // stash_Ogre__Math is from above
        newCONSTSUB(stash_Ogre__Math, "POS_INFINITY", newSVnv(Ogre::Math::POS_INFINITY));
        newCONSTSUB(stash_Ogre__Math, "NEG_INFINITY", newSVnv(Ogre::Math::NEG_INFINITY));
        newCONSTSUB(stash_Ogre__Math, "PI", newSVnv(Ogre::Math::PI));
        newCONSTSUB(stash_Ogre__Math, "TWO_PI", newSVnv(Ogre::Math::TWO_PI));
        newCONSTSUB(stash_Ogre__Math, "HALF_PI", newSVnv(Ogre::Math::HALF_PI));
        newCONSTSUB(stash_Ogre__Math, "fDeg2Rad", newSVnv(Ogre::Math::fDeg2Rad));
        newCONSTSUB(stash_Ogre__Math, "fRad2Deg", newSVnv(Ogre::Math::fRad2Deg));
    }
