# Describing complex mark:mark
#     {urn:ietf:params:xml:ns:mark-1.0}mark
#
# Produced by XML::Compile::Translate::Template version undef
#          on Wed Dec 30 16:32:17 2015
#
# BE WARNED: in most cases, the example below cannot be used without
# interpretation.  The comments will guide you.
#
# xmlns:ds        http://www.w3.org/2000/09/xmldsig#
# xmlns:mark      urn:ietf:params:xml:ns:mark-1.0
# xmlns:smd       urn:ietf:params:xml:ns:signedMark-1.0
# xmlns:xsd       http://www.w3.org/2001/XMLSchema

# is a mark:markType
{ # sequence of trademark, treatyOrStatute, court

  # is a mark:trademarkType
  # occurs any number of times
  trademark =>
  [ { # sequence of id, markName, holder, contact, jurisdiction,
      #   class, label, goodsAndServices, apId, apDate, regNum,
      #   regDate, exDate

      # is a xsd:token
      # Pattern: \d+-\d+
      id => "token",

      # is a xsd:token
      markName => "token",

      # is a mark:holderType
      # occurs 1 <= # <= unbounded times
      holder =>
      [ { # is a xsd:token
          # becomes an attribute
          # Enum: assignee licensee owner
          entitlement => "owner",

          # sequence of name, org, addr, voice, fax, email

          # is a xsd:token
          # is optional
          name => "token",

          # is a xsd:token
          # is optional
          org => "token",

          # is a mark:addrType
          addr =>
          { # sequence of street, city, sp, pc, cc

            # is a xsd:token
            # occurs 1 <= # <= 3 times
            street => [ "token", ],

            # is a xsd:token
            city => "token",

            # is a xsd:token
            # is optional
            sp => "token",

            # is a xsd:token
            # is optional
            # length <= 16
            pc => "token",

            # is a xsd:token
            # fixed length of 2
            cc => "token", },

          # is a mark:e164Type
          # voice is simple value with attributes
          # is optional
          voice =>
          { # is a xsd:token
            # becomes an attribute
            x => "token",

            # is a xsd:token
            # string content of the container
            _ => "token", },

          # is a mark:e164Type
          # fax is simple value with attributes
          # is optional
          fax =>
          { # is a xsd:token
            # becomes an attribute
            x => "token",

            # is a xsd:token
            # string content of the container
            _ => "token", },

          # is a xsd:token
          # is optional
          # length >= 1
          email => "token", }, ],

      # is a mark:contactType
      # occurs any number of times
      contact =>
      [ { # is a xsd:token
          # becomes an attribute
          # Enum: agent owner thirdparty
          type => "owner",

          # sequence of name, org, addr, voice, fax, email

          # is a xsd:token
          name => "token",

          # is a xsd:token
          # is optional
          org => "token",

          # is a mark:addrType
          # complex structure shown above
          addr => {},

          # is a mark:e164Type
          # voice is simple value with attributes
          voice =>
          { # is a xsd:token
            # becomes an attribute
            x => "token",

            # is a xsd:token
            # string content of the container
            _ => "token", },

          # is a mark:e164Type
          # fax is simple value with attributes
          # is optional
          fax =>
          { # is a xsd:token
            # becomes an attribute
            x => "token",

            # is a xsd:token
            # string content of the container
            _ => "token", },

          # is a xsd:token
          # length >= 1
          email => "token", }, ],

      # is a xsd:token
      # fixed length of 2
      jurisdiction => "token",

      # is a xsd:integer
      # occurs any number of times
      class => [ 42, ],

      # is a xsd:token
      # occurs any number of times
      # length <= 63
      # length >= 1
      # Pattern: [a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?
      label => [ "token", ],

      # is a xsd:token
      goodsAndServices => "token",

      # is a xsd:token
      # is optional
      apId => "token",

      # is a xsd:dateTime
      # is optional
      apDate => "2006-10-06T00:23:02Z",

      # is a xsd:token
      regNum => "token",

      # is a xsd:dateTime
      regDate => "2006-10-06T00:23:02Z",

      # is a xsd:dateTime
      # is optional
      exDate => "2006-10-06T00:23:02Z", }, ],

  # is a mark:treatyOrStatuteType
  # occurs any number of times
  treatyOrStatute =>
  [ { # sequence of id, markName, holder, contact, protection,
      #   label, goodsAndServices, refNum, proDate, title, execDate

      # is a xsd:token
      # Pattern: \d+-\d+
      id => "token",

      # is a xsd:token
      markName => "token",

      # is a mark:holderType
      # complex structure shown above
      # occurs 1 <= # <= unbounded times
      holder => [{},],

      # is a mark:contactType
      # complex structure shown above
      # occurs any number of times
      contact => [{},],

      # is a mark:protectionType
      # occurs 1 <= # <= unbounded times
      protection =>
      [ { # sequence of cc, region, ruling

          # is a xsd:token
          # fixed length of 2
          cc => "token",

          # is a xsd:token
          # is optional
          region => "token",

          # is a xsd:token
          # occurs any number of times
          # fixed length of 2
          ruling => [ "token", ], }, ],

      # is a xsd:token
      # occurs any number of times
      # length <= 63
      # length >= 1
      # Pattern: [a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?
      label => [ "token", ],

      # is a xsd:token
      goodsAndServices => "token",

      # is a xsd:token
      refNum => "token",

      # is a xsd:dateTime
      proDate => "2006-10-06T00:23:02Z",

      # is a xsd:token
      title => "token",

      # is a xsd:dateTime
      execDate => "2006-10-06T00:23:02Z", }, ],

  # is a mark:courtType
  # occurs any number of times
  court =>
  [ { # sequence of id, markName, holder, contact, label,
      #   goodsAndServices, refNum, proDate, cc, region, courtName

      # is a xsd:token
      # Pattern: \d+-\d+
      id => "token",

      # is a xsd:token
      markName => "token",

      # is a mark:holderType
      # complex structure shown above
      # occurs 1 <= # <= unbounded times
      holder => [{},],

      # is a mark:contactType
      # complex structure shown above
      # occurs any number of times
      contact => [{},],

      # is a xsd:token
      # occurs any number of times
      # length <= 63
      # length >= 1
      # Pattern: [a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?
      label => [ "token", ],

      # is a xsd:token
      goodsAndServices => "token",

      # is a xsd:token
      refNum => "token",

      # is a xsd:dateTime
      proDate => "2006-10-06T00:23:02Z",

      # is a xsd:token
      # fixed length of 2
      cc => "token",

      # is a xsd:token
      # occurs any number of times
      region => [ "token", ],

      # is a xsd:token
      courtName => "token", }, ], }
