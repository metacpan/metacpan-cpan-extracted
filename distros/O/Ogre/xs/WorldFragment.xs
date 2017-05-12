MODULE = Ogre     PACKAGE = Ogre::SceneQuery::WorldFragment
## note: this is a struct.
## For now I assume it is read-only.
## There is a typedef for WorldFragment in perlOGRE.h .

## thanks to Thomas Busch whose example I followed
## from his Lucene module for dealing with classes
## that are nested more than one level deep

int
fragmentType(THIS)
    WorldFragment * THIS
  CODE:
    RETVAL = THIS->fragmentType;
  OUTPUT:
    RETVAL

Vector3 *
singleIntersection(THIS)
    WorldFragment * THIS
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->singleIntersection;
  OUTPUT:
    RETVAL

## std::list< Plane > * planes
## note: I return the list of Planes as an aref
SV *
planes(THIS)
    WorldFragment *THIS
  CODE:
    AV *planes_av = (AV *) sv_2mortal((SV *) newAV());
    std::list< Plane >::const_iterator it;
    std::list< Plane >::const_iterator itEnd = THIS->planes->end();

    for (it = THIS->planes->begin(); it != itEnd; ++it) {
        // put C++ Plane into Perl SV*
        SV *plane_sv = sv_newmortal();
        const Plane *pp = &(*it);
        TMOGRE_OUT(plane_sv, pp, Plane);

        av_push(planes_av, plane_sv);
    }

    // return the array ref
    RETVAL = newRV((SV *) planes_av);
  OUTPUT:
    RETVAL

## this is skipped because void*
## void * 	geometry

RenderOperation *
renderOp(THIS)
    WorldFragment * THIS
  CODE:
    RETVAL = THIS->renderOp;
  OUTPUT:
    RETVAL
