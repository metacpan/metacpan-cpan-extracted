MODULE = Ogre     PACKAGE = Ogre::PlaneBoundedVolume

## need to add tests

PlaneBoundedVolume *
PlaneBoundedVolume::new(...)
  CODE:
    if (items == 1) {
        RETVAL = new PlaneBoundedVolume;
    }
    else if (looks_like_number(ST(1))) {
        RETVAL = new PlaneBoundedVolume((Plane::Side)SvIV(ST(1)));
    }
  OUTPUT:
    RETVAL

void
PlaneBoundedVolume::DESTROY()

bool
PlaneBoundedVolume::intersects(...)
  PREINIT:
    const char *usage = "Usage: Ogre::PlaneBoundedVolume::intersects(THIS, {Sphere|AxisAlignedBox})\n";
  CODE:
    if (sv_isobject(ST(1))) {
        if (sv_derived_from(ST(1), "Ogre::Sphere")) {
            Sphere *w = (Sphere *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        else if (sv_derived_from(ST(1), "Ogre::AxisAlignedBox")) {
            AxisAlignedBox *w = (AxisAlignedBox *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
            RETVAL = THIS->intersects(*w);
        }
        // xxx: returns a damn std::pair<bool, Real>
        //else if (sv_derived_from(ST(1), "Ogre::Ray")) {
        //    Ray *w = (Ray *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        //    RETVAL = THIS->intersects(*w);
        //}
        else {
            croak("%s", usage);
        }
    }
    else {
        croak("%s", usage);
    }
  OUTPUT:
    RETVAL


## Public Attributes

## XXX: hmmm, I need to do the other public attrs like this if possible
int
PlaneBoundedVolume::outside(...)
  CODE:
      if (items == 2 && looks_like_number(ST(1))) {
          THIS->outside = (Plane::Side)SvIV(ST(1));
      }
      RETVAL = THIS->outside;
  OUTPUT:
    RETVAL

## xxx: this sucks - fix when typemap PlaneList (attribute 'planes')
void
PlaneBoundedVolume::push_back_plane(Plane *plane)
  CODE:
    THIS->planes.push_back(*plane);
