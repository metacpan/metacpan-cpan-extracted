MODULE = Ogre     PACKAGE = Ogre::RibbonTrail

void
RibbonTrail::addNode(Node *n)

void
RibbonTrail::removeNode(Node *n)

## NodeIterator RibbonTrail::getNodeIterator()

void
RibbonTrail::setTrailLength(Real len)

Real
RibbonTrail::getTrailLength()

void
RibbonTrail::setMaxChainElements(size_t maxElements)

void
RibbonTrail::setNumberOfChains(size_t numChains)

void
RibbonTrail::clearChain(size_t chainIndex)

void
RibbonTrail::setInitialColour(size_t chainIndex, ...)
  CODE:
    if (items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Colour")) {
        const ColourValue *colour = (const ColourValue *) SvIV((SV *) SvRV(ST(2)));   // TMOGRE_IN
        THIS->setInitialColour(chainIndex, *colour);
    }
    else if (items >= 5) {
        Real a = 1.0;
        if (items == 6) a = (Real)SvNV(ST(5));
        THIS->setInitialColour(chainIndex, (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)));
    }
    else {
        croak("Usage: Ogre::RibbonTrail::setInitialColour(THIS, chainIndex, col) or (THIS, chainIndex, r, g, b [, a])\n");
    }

ColourValue *
RibbonTrail::getInitialColour(size_t chainIndex)
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getInitialColour(chainIndex);
  OUTPUT:
    RETVAL

void
RibbonTrail::setColourChange(size_t chainIndex, ...)
  CODE:
    if (items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2), "Ogre::Colour")) {
        const ColourValue *colour = (const ColourValue *) SvIV((SV *) SvRV(ST(2)));   // TMOGRE_IN
        THIS->setColourChange(chainIndex, *colour);
    }
    else if (items == 6) {
        THIS->setColourChange(chainIndex, (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)), (Real)SvNV(ST(5)));
    }
    else {
        croak("Usage: Ogre::RibbonTrail::setColourChange(THIS, chainIndex, col) or (THIS, chainIndex, r, g, b , a)\n");
    }

void
RibbonTrail::setInitialWidth(size_t chainIndex, Real width)

Real
RibbonTrail::getInitialWidth(size_t chainIndex)

void
RibbonTrail::setWidthChange(size_t chainIndex, Real widthDeltaPerSecond)

Real
RibbonTrail::getWidthChange(size_t chainIndex)

ColourValue *
RibbonTrail::getColourChange(size_t chainIndex)
  CODE:
    RETVAL = new ColourValue;
    *RETVAL = THIS->getColourChange(chainIndex);
  OUTPUT:
    RETVAL

void
RibbonTrail::nodeUpdated(const Node *node)

void
RibbonTrail::nodeDestroyed(const Node *node)

String
RibbonTrail::getMovableType()
