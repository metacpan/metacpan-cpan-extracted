# This file is a testcase for the highlighting of Ruby code
# It's not executable code, but a collection of code snippets
#

require 'Config'
require 'DO/Clients'
require 'DO/DBClients'

  def CGI::escapeElement(string, *elements)
    elements = elements[0] if elements[0].kind_of?(Array)
    unless elements.empty?
      string.gsub(/<\/?(?:#{elements.join("|")})(?!\w)(?:.|\n)*?>/ni) do
        CGI::escapeHTML($&)
      end
    else
      string
    end
  end

case inputLine
  when "debug"
    dumpDebugInfo
    dumpSymbols
  when /p\s+(\w+)/
    dumpVariable($1)
  when "quit", "exit"
    exit
  else
    print "Illegal command: #{inputLine}"
end


kind = case year #hi there
         when 1850..1889 then "Blues"
         when 1940..1950 then "Bebop"
         else                 "Jazz"
       end

  # URL-encode a string.
  #   url_encoded_string = CGI::escape("'Stop!' said Fred")
  #      # => "%27Stop%21%27+said+Fred"
  def CGI::escape(string)
    string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end.tr(' ', '+')
  end


# Class ClientManager
#
# definition : Import, store and export the various data used by the application.
# This class is the sole interface between the application and the underlying database.

mon, day, year = $1, $2, $3 if /(\d\d)-(\d\d)-(\d\d)/
puts "a = #{a}" if fDebug
print total unless total == 0

while gets
  next if /^#/            # Skip comments
  parseLine unless /^$/   # Don't parse empty lines
end

if artist == "John Coltrane" #hi there
  artist = "'Trane" #hi there
end unless nicknames == "no" #hi there

handle = if aSong.artist == "Gillespie" then #hi there
           "Dizzy"
         elsif aSong.artist == "Parker" then
           "Bird"
         else #hi there
           "unknown"
         end

if aSong.artist == "Gillespie" then  handle = "Dizzy"
elsif aSong.artist == "Parker" then  handle = "Bird"
else  handle = "unknown"
end #hi there


 case line
  when /title=(.*)/
    puts "Title is #$1"
  when /track=(.*)/
    puts "Track is #$1"
  when /artist=(.*)/
    puts "Artist is #$1"
end

case shape
  when Square, Rectangle
    # ...
  when Circle
    # ...
  when Triangle
    # ...
  else
    # ...
end 


until playList.duration > 60 #hi there
  playList.add(songList.pop)
end

3.times do
  print "Ho! "
end

loop {
  # block ...
}

songList.each do |aSong|
  aSong.play
end


i = 0
doUntil(i > 3) {
  print i, " "
  i += 1
}

def system_call
	# ... code which throws SystemCallError
rescue SystemCallError
	$stderr.print "IO failed: " + $!
	opFile.close
	File.delete(opName)
	raise
end

class ClientManager
	
	# constructor
	def initialize(dbase)
		@dbClient = DBClient.new(dbase)
		@clients = Clients.new
	end
	
	def prout(a, b, xy="jj") 24 end 
	###############################################################
	#
	# CLIENTS SECTION
	#
	###############################################################
	
	# update the clients object by retrieving the related data from the database
	# returns the number of clients
	def refreshClients
		@clients.clean
		unless @sqlQuery.nil? then
			@sqlQuery.selectClient.each do |row|
				@clients.addClient(row[0],row[1],row[2],row[3],row[4],row[5], row[6], row[7], row[8])
			end
		else
			puts "SqlQuery wasn't created : cannot read data from database"
		end
		return @clients.length
	end
	
end

  # Mixin module for HTML version 3 generation methods.
  module Html3 # :nodoc:

    # The DOCTYPE declaration for this version of HTML
    def doctype
      %|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">|
    end

    # Initialise the HTML generation methods for this version.
    def element_init
      extend TagMaker
      methods = ""
      # - -
      for element in %w[ HTML HEAD BODY P PLAINTEXT DT DD LI OPTION tr
          th td ]
        methods += <<-BEGIN + nO_element_def(element) + <<-END
          def #{element.downcase}(attributes = {})
        BEGIN
          end
        END
      end
      eval(methods)
    end

  end

# following snippet from Webrick's log.rb

# test cases for general delimited input
# quoted strings
%Q|this is a string|
%Q{this is a string}
%Q(this is a string)
%Q<this is a string>
%Q[this is a string]

%|also a string|
%{also a string}
%(also a string)
%<also a string>
%[also a string]

# apostrophed strings
%q|apostrophed|
%q{apostrophed}
%q(apostrophed)
%q<apostrophed>
%q[apostrophed]

# regular expressions
%r{expression}
%r(expression)
%r<expression>
%r[expression]
%r|expression|

# shell commands
%x{ls -l}
%x(ls -l)
%x<ls -l>
%x[ls -l]

# sometimes it's useful to have the command on multiple lines
%x{ls -l |
grep test }

# token array
%w{one two three}
%w(one two three)
%w<one two three>
%w[one two three]

# snippet from Net::IMAP
# I object to putting String, Integer and Array into kernel methods.
# While these classes are builtin in Ruby, this is an implementation detail
# that should not be exposed to the user.
# If we want to handle all std-lib classes, fine. But then they should be in their
# own std-lib keyword category.

def send_data(data)
      case data
      when nil
        put_string("NIL")
      when String
        send_string_data(data)
      when Integer
        send_number_data(data)
      when Array
        send_list_data(data)
      when Time
        send_time_data(data)
      when Symbol
        send_symbol_data(data)
      else
        data.send_data(self)
      end
end

